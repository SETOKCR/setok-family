<#
.SYNOPSIS
  ST-ID-001: Authentik pilot identity foundation (Story-specific, not a reusable module).

.DESCRIPTION
  Git desired state -> PowerShell over SSH -> Proxmox VM -> Ubuntu -> Docker Compose -> Authentik
  -> observed-state verification -> evidence.

  Steps (each is idempotent / re-checks before acting):
    Plan        read-only: Proxmox target, VM 210 fingerprint, VMID/IP availability.
    CreateVm    creates VM 220 from the Ubuntu cloud image if absent; STOPs if VMID is taken by anything else.
    Runtime     installs docker.io, docker-compose-v2, qemu-guest-agent, ufw (LAN-only allow rules).
    Deploy      copies compose.yml, creates .env on the VM (secrets generated ON the VM, never returned),
                sets AUTHENTIK_BOOTSTRAP_PASSWORD_HASH from a DPAPI-stored password, starts the stack.
    Verify      health, mounts, exposure, scope scan, akadmin check, VM 210 unchanged.
    Backup      pg_dump -Fc streamed to valhalla; verified with pg_restore --list.
    Usage       CPU/RAM utilization snapshot.

  Secrets: the akadmin password lives only in a DPAPI file under %LOCALAPPDATA%; it is piped over SSH stdin
  and never written to the VM disk, Git, logs or evidence. PG_PASS and AUTHENTIK_SECRET_KEY never leave the VM.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Plan','CreateVm','Runtime','Deploy','Verify','Backup','Usage')][string]$Step)

$ErrorActionPreference = 'Stop'
$repo     = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$desired  = Get-Content (Join-Path $repo 'infra\authentik\st-id-001.desired.json') -Raw | ConvertFrom-Json
$evidence = Join-Path $repo 'docs\evidence\ST-ID-001'
$local    = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$pwFile   = Join-Path $local 'authentik-akadmin.xml'
$backups  = Join-Path $local 'backups\authentik'
$key      = Join-Path $HOME '.ssh\setok_family_idp_ed25519'
$vm       = $desired.vm
$vmIp     = $vm.ip.Split('/')[0]
$vm210Sha = '77388d3a22ebedc70c9fe5daf4b37843b699d88df26c9a62e62ba59be588e9d2'  # observed before any mutation

function Pve([string]$Script) {
    $out = $Script | ssh -o BatchMode=yes -o IdentitiesOnly=yes -i (Join-Path $HOME '.ssh\id_ed25519_setok_proxmox') "root@$($desired.proxmox.sshHost)" "tr -d '\r' | bash -s" 2>&1
    if ($LASTEXITCODE) { throw "pve-02 script failed:`n$out" }
    $out
}
function Guest([string]$Script, [string]$Stdin) {
    $cmd = 'sudo bash -c ' + "'" + $Script.Replace("'", "'\''") + "'"
    $sshArgs = @('-o','BatchMode=yes','-o','StrictHostKeyChecking=accept-new','-i',$key,"$($vm.ciuser)@$vmIp",$cmd)
    $out = if ($PSBoundParameters.ContainsKey('Stdin')) { $Stdin | ssh @sshArgs 2>&1 } else { ssh @sshArgs 2>&1 }
    if ($LASTEXITCODE) { throw "guest script failed:`n$out" }
    $out
}
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 8 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Get-Vm210Fingerprint { ((Pve "sha256sum /etc/pve/qemu-server/210.conf | cut -d' ' -f1; qm status 210") -join ' ').Trim() }
function Get-AkadminPassword {
    if (-not (Test-Path $pwFile)) {
        New-Item -ItemType Directory -Force $local | Out-Null
        $bytes = [byte[]]::new(32); [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
        $plain = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
        ConvertTo-SecureString $plain -AsPlainText -Force | Export-Clixml $pwFile
    }
    [Net.NetworkCredential]::new('', (Import-Clixml $pwFile)).Password
}

switch ($Step) {
    'Plan' {
        $p = Pve @"
echo node=`$(hostname)
echo vm210=`$(sha256sum /etc/pve/qemu-server/210.conf | cut -d' ' -f1) `$(qm status 210)
echo vmid220=`$(test -e /etc/pve/qemu-server/220.conf && grep '^name:' /etc/pve/qemu-server/220.conf || echo absent)
echo ip=`$(ping -c1 -W1 $vmIp >/dev/null 2>&1 && echo in-use || echo no-reply)
echo image=`$(test -f $($vm.image) && echo present || echo missing)
echo memfree=`$(free -m | awk '/Mem:/{print `$7}')MiB
pvesm status | awk 'NR==1||/local-lvm/'
"@
        $p
        Save-Evidence 'plan' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); output = $p; desired = $desired.vm })
    }
    'CreateVm' {
        if ((Get-Vm210Fingerprint) -notlike "$vm210Sha*") { throw 'STOP: VM 210 config changed before CreateVm.' }
        if (-not (Test-Path $key)) { ssh-keygen -q -t ed25519 -N '' -C 'setok-family-idp-01 (ST-ID-001)' -f $key | Out-Null }
        $pub = (Get-Content "$key.pub" -Raw).Trim()
        $out = Pve @"
set -euo pipefail
conf=/etc/pve/qemu-server/$($vm.vmid).conf
if [ -e "`$conf" ]; then
  grep -q '^name: $($vm.name)`$' "`$conf" || { echo 'STOP: VMID $($vm.vmid) exists with another name'; exit 3; }
  echo 'VM exists; not recreating'; qm status $($vm.vmid); exit 0
fi
if ping -c1 -W1 $vmIp >/dev/null 2>&1; then echo 'STOP: $vmIp already answers'; exit 4; fi
tmp=`$(mktemp); echo '$pub' > "`$tmp"
qm create $($vm.vmid) --name $($vm.name) --cores $($vm.cores) --memory $($vm.memoryMiB) --balloon $($vm.balloon) \
  --cpu host --machine q35 --ostype l26 --scsihw virtio-scsi-single --agent enabled=1 \
  --net0 virtio,bridge=$($vm.bridge),firewall=1 --serial0 socket --vga serial0 --onboot 1 \
  --description 'SETOK Family pilot Authentik IdP (ST-ID-001). Managed from SETOKCR/setok-family.'
qm set $($vm.vmid) --scsi0 $($vm.storage):0,import-from=$($vm.image),discard=on,ssd=1
qm resize $($vm.vmid) scsi0 $($vm.diskGiB)G
qm set $($vm.vmid) --ide2 $($vm.storage):cloudinit --boot order=scsi0 --ciuser $($vm.ciuser) --sshkeys "`$tmp" \
  --ipconfig0 ip=$($vm.ip),gw=$($vm.gateway) --nameserver $($vm.nameserver) --searchdomain $($vm.searchdomain)
rm -f "`$tmp"
qm start $($vm.vmid)
qm status $($vm.vmid)
"@
        $out
        Save-Evidence 'createvm' ([pscustomobject]@{ output = $out; vm210 = Get-Vm210Fingerprint })
    }
    'Runtime' {
        $out = Guest @'
set -euo pipefail
cloud-init status --wait >/dev/null || true
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq docker.io docker-compose-v2 qemu-guest-agent ufw >/dev/null
systemctl enable --now docker qemu-guest-agent >/dev/null 2>&1 || systemctl start qemu-guest-agent
ufw default deny incoming >/dev/null; ufw default allow outgoing >/dev/null
for p in 22 9000 9443; do ufw allow from 192.168.89.0/24 to any port $p proto tcp >/dev/null; done
ufw --force enable >/dev/null
lsb_release -ds; docker --version; docker compose version; ufw status
'@
        $out
        Save-Evidence 'runtime' ([pscustomobject]@{ output = $out })
    }
    'Deploy' {
        $compose = Get-Content (Join-Path $repo 'infra\authentik\compose.yml') -Raw
        Guest "install -d -m 0750 /opt/authentik && tr -d '\r' > /opt/authentik/compose.yml" $compose | Out-Null
        $out = Guest @'
set -euo pipefail
cd /opt/authentik
install -d -m 0750 -o 1000 -g 1000 data certs custom-templates
chown 1000:1000 data certs custom-templates && chmod 0750 data certs custom-templates
if [ ! -f .env ]; then
  umask 077
  { echo "PG_PASS=$(openssl rand -base64 36 | tr -d '\n=+/')"
    echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')"; } > .env
  echo ".env created"
else echo ".env exists; secrets kept"; fi
chmod 600 .env; chown root:root .env
docker compose pull -q
'@
        $out
        $hasHash = (Guest "grep -c '^AUTHENTIK_BOOTSTRAP_PASSWORD_HASH=' /opt/authentik/.env || true").Trim()
        if ($hasHash -eq '0') {
            $hash = Guest "cd /opt/authentik && tr -d '\r\n' | docker compose run --rm -T server hash_password 2>/dev/null | grep -o 'pbkdf2_sha256\$[^[:space:]]*' | tail -1" (Get-AkadminPassword)
            $hash = "$hash".Trim()
            if ($hash -notmatch '^pbkdf2_sha256\$') { throw 'Could not obtain bootstrap password hash.' }
            Guest "tr -d '\r' >> /opt/authentik/.env" ("AUTHENTIK_BOOTSTRAP_PASSWORD_HASH='" + $hash + "'") | Out-Null
            Remove-Variable hash
            'Bootstrap hash written to .env (value not shown).'
        } else { 'Bootstrap hash already present; unchanged.' }
        $up = Guest 'cd /opt/authentik && docker compose up -d 2>&1 | tail -5 && docker compose ps --format "{{.Service}} {{.State}} {{.Health}}"'
        $up
        Save-Evidence 'deploy' ([pscustomobject]@{ output = $out; up = $up })
    }
    'Verify' {
        $pw = Get-AkadminPassword
        $py = @"
import sys
from authentik.core.models import User, Application, Group, Token
from authentik.providers.oauth2.models import OAuth2Provider
from authentik.core.models import Provider, Source
from authentik.outposts.models import Outpost
pw = sys.stdin.readline().rstrip('\n')
ak = User.objects.filter(username='akadmin').first()
print('akadmin_exists', ak is not None)
print('akadmin_password_ok', bool(ak and ak.check_password(pw)))
print('akadmin_superuser', bool(ak and ak.is_superuser))
print('users', sorted(u.username for u in User.objects.all()))
print('applications', Application.objects.count())
print('providers', Provider.objects.count())
print('oauth2_providers', OAuth2Provider.objects.count())
print('sources', sorted(s.slug for s in Source.objects.all()))
print('outposts', sorted((o.name, o.type) for o in Outpost.objects.all()))
print('tokens', Token.objects.count())
"@
        Guest "tr -d '\r' > /tmp/st-id-001-scan.py" $py | Out-Null
        $scan = Guest 'cd /opt/authentik && docker compose cp /tmp/st-id-001-scan.py worker:/tmp/scan.py >/dev/null && rm -f /tmp/st-id-001-scan.py && tr -d "\r" | docker compose exec -T worker ak shell -c "exec(open(\"/tmp/scan.py\").read())" 2>/dev/null | grep -E "^(akadmin|users|applications|providers|oauth2|sources|outposts|tokens)"; docker compose exec -T worker rm -f /tmp/scan.py' $pw
        Remove-Variable pw
        $state = Guest @'
cd /opt/authentik
echo "## ps"; docker compose ps --format '{{.Service}} {{.State}} {{.Health}} {{.Image}}'
echo "## health"; for p in live ready; do echo "$p $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:9000/-/health/$p/)"; done
echo "ui $(curl -s -o /dev/null -w '%{http_code}' -L http://127.0.0.1:9000/)"
echo "api $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:9000/api/v3/root/config/)"
echo "version $(docker inspect $(docker compose ps -q server) --format '{{index .Config.Labels "org.opencontainers.image.version"}}')"
echo "## mounts"; for s in server worker postgresql; do echo "$s $(docker inspect $(docker compose ps -q $s) --format '{{range .Mounts}}{{.Source}}->{{.Destination}} {{end}}')"; done
echo "docker_sock_mounted $(docker inspect $(docker compose ps -q worker) --format '{{range .Mounts}}{{.Source}} {{end}}' | grep -c docker.sock || true)"
echo "## env_perms"; stat -c '%a %U:%G %n' .env
echo "## exposure"; ip -br -4 addr | grep -v '^lo'; ss -Hltn | awk '{print $4}' | sort -u | tr '\n' ' '; echo; ufw status | head -12
echo "## volume"; docker volume inspect authentik_database --format '{{.Name}} {{.Mountpoint}}'
'@
        $vm210 = Get-Vm210Fingerprint
        $report = [pscustomobject]@{
            observedAt = (Get-Date).ToUniversalTime().ToString('o')
            vm210      = [pscustomobject]@{ observed = $vm210; unchanged = ($vm210 -like "$vm210Sha*") }
            state      = $state
            scopeScan  = $scan
        }
        Save-Evidence 'verify' $report
        $state; $scan; "vm210: $vm210"
    }
    'Backup' {
        New-Item -ItemType Directory -Force $backups | Out-Null
        $file = Join-Path $backups ("authentik-{0}.dump" -f (Get-Date -Format 'yyyyMMddTHHmmss'))
        $dumpArgs = @('-o','BatchMode=yes','-i',$key,"$($vm.ciuser)@$vmIp",'sudo docker compose -f /opt/authentik/compose.yml exec -T postgresql pg_dump -U authentik -d authentik -Fc')
        $p = Start-Process ssh -ArgumentList $dumpArgs -RedirectStandardOutput $file -NoNewWindow -Wait -PassThru
        if ($p.ExitCode) { throw "pg_dump failed ($($p.ExitCode))" }
        $sha = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
        $size = (Get-Item $file).Length
        $listArgs = @('-o','BatchMode=yes','-i',$key,"$($vm.ciuser)@$vmIp",'sudo docker compose -f /opt/authentik/compose.yml exec -T postgresql pg_restore --list')
        $tmpOut = New-TemporaryFile
        $q = Start-Process ssh -ArgumentList $listArgs -RedirectStandardInput $file -RedirectStandardOutput $tmpOut -NoNewWindow -Wait -PassThru
        $toc = Get-Content $tmpOut; Remove-Item $tmpOut
        $tables = @($toc | Select-String ' TABLE DATA ').Count
        if ($q.ExitCode -or $tables -lt 50) { throw "Backup verification failed (exit $($q.ExitCode), $tables table-data entries)." }
        $r = [pscustomobject]@{ location = $file.Replace($env:LOCALAPPDATA, '%LOCALAPPDATA%'); bytes = $size; sha256 = $sha; tocEntries = $toc.Count; tableDataEntries = $tables; format = 'pg_dump custom (-Fc)' }
        Save-Evidence 'backup' $r
        $r | Format-List
    }
    'Usage' {
        $u = Guest @'
echo "## uptime"; uptime
echo "## free -m"; free -m
echo "## docker stats"; docker stats --no-stream --format '{{.Name}} cpu={{.CPUPerc}} mem={{.MemUsage}} ({{.MemPerc}})'
echo "## disk"; df -h / | tail -1
'@
        Save-Evidence 'usage' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); output = $u })
        $u
    }
}
