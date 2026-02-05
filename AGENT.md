# Agent Instructions: NixOS Azure Dev VM

You are setting up a NixOS development VM on Azure for your user. Follow these steps exactly.

## What the human needs to do (only 2 things)

1. **Authenticate Tailscale** — you will give them a URL to click
2. **Add VM's SSH key to GitHub** — you will give them the public key to paste

Everything else is automated.

## Prerequisites

- Azure CLI (`az`) installed and logged in
- SSH key pair on the local machine (`~/.ssh/id_ed25519.pub` or similar)
- Tailscale account (free at https://tailscale.com)

## Step 1: Create the Azure VM

```bash
# Pick your settings
RESOURCE_GROUP="<user>-dev-vm"
LOCATION="uksouth"            # or any Azure region
VM_NAME="<user>-vm"
VM_SIZE="Standard_B8as_v2"   # 8 vCPU, 32GB RAM, ~$60/mo burstable

# Create resource group
az group create -n "$RESOURCE_GROUP" -l "$LOCATION"

# Create VM — CRITICAL: --security-type Standard disables Secure Boot
az vm create \
  -g "$RESOURCE_GROUP" \
  -n "$VM_NAME" \
  --image Canonical:ubuntu-24_04-lts:server:latest \
  --size "$VM_SIZE" \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_ed25519.pub \
  --security-type Standard \
  --os-disk-size-gb 30 \
  --public-ip-sku Standard
```

**CRITICAL**: `--security-type Standard` is mandatory. NixOS GRUB is unsigned and will not boot with Secure Boot enabled. If you forget this, the VM will show "prohibited by secure boot policy" and you must delete and recreate.

Save the public IP from the output.

### Optional: Add a 128GB data disk for /home

```bash
az vm disk attach \
  -g "$RESOURCE_GROUP" \
  --vm-name "$VM_NAME" \
  --new \
  --name "${VM_NAME}-data" \
  --size-gb 128 \
  --sku Premium_LRS
```

## Step 2: Open SSH in NSG (temporary)

```bash
NSG_NAME=$(az network nsg list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
az network nsg rule create \
  -g "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  -n allow-ssh \
  --priority 100 \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow
```

## Step 3: Wait for VM to be ready

SSH in and verify cloud-init is done (root partition expanded):

```bash
VM_IP=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" -d --query publicIps -o tsv)
# Wait ~60 seconds after creation, then:
ssh azureuser@$VM_IP "cloud-init status --wait && df -h /"
```

Root should show ~29GB. If it shows ~2GB, wait and retry.

## Step 4: Run the bootstrap script

Read the user's SSH public key and pass it to the bootstrap:

```bash
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)

ssh azureuser@$VM_IP "curl -fsSL https://raw.githubusercontent.com/jorgensandhaug/nixos-dev-vm/main/bootstrap.sh | bash -s -- \
  --ssh-key '$SSH_KEY' \
  --hostname '$VM_NAME' \
  --username '<desired-username>' \
  --timezone 'Europe/Stockholm' \
  --data-disk yes"
```

The script will:
1. Detect filesystem UUIDs automatically
2. Install Nix and build the NixOS system
3. Install GRUB (preserving Ubuntu's EFI shim)
4. Reboot into NixOS

**This takes 5-10 minutes.** The SSH connection will drop when it reboots.

## Step 5: Verify NixOS booted

Wait ~60 seconds after reboot, then SSH in with the NEW username:

```bash
ssh <username>@$VM_IP "uname -a"
```

You should see `Linux <hostname> ... NixOS ...`. If SSH times out, wait longer — NixOS needs to start systemd-networkd and get a DHCP lease.

If it doesn't come back after 3 minutes, check the serial console:
```bash
az vm boot-diagnostics get-boot-log -g "$RESOURCE_GROUP" -n "$VM_NAME"
```

## Step 6: Set up Tailscale

```bash
ssh <username>@$VM_IP "sudo tailscale up --ssh --accept-routes"
```

This prints a URL. **Tell the human to open it and authenticate.** This is the one thing they must do manually.

After auth, get the Tailscale IP:
```bash
ssh <username>@$VM_IP "tailscale ip -4"
```

## Step 7: Lock down the VM

Remove public IP and SSH NSG rule — Tailscale is the only access method now:

```bash
NIC_NAME=$(az network nic list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
IP_CONFIG=$(az network nic ip-config list -g "$RESOURCE_GROUP" --nic-name "$NIC_NAME" --query "[0].name" -o tsv)

# Remove public IP from NIC
az network nic ip-config update \
  -g "$RESOURCE_GROUP" \
  --nic-name "$NIC_NAME" \
  -n "$IP_CONFIG" \
  --remove publicIpAddress

# Delete public IP resource
PIP_NAME=$(az network public-ip list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
az network public-ip delete -g "$RESOURCE_GROUP" -n "$PIP_NAME"

# Delete SSH NSG rule
az network nsg rule delete -g "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" -n allow-ssh
```

**Verify Tailscale access still works** (wait ~30s after removing public IP):
```bash
TAILSCALE_IP=$(ssh <username>@$VM_IP "tailscale ip -4")  # get this BEFORE removing public IP
ssh <username>@$TAILSCALE_IP "hostname"
```

## Step 8: Install Claude Code (optional)

```bash
ssh <username>@$TAILSCALE_IP "mkdir -p ~/.config/nixpkgs && echo '{ allowUnfree = true; }' > ~/.config/nixpkgs/config.nix && nix-env -iA nixpkgs.claude-code"
```

## Step 9: Install tsgo (optional)

```bash
ssh <username>@$TAILSCALE_IP "bun add -g @typescript/native-preview"
```

## Step 10: Get the VM's SSH public key

The VM auto-generates an SSH keypair. Get it for the human to add to GitHub:

```bash
ssh <username>@$TAILSCALE_IP "cat ~/.ssh/id_ed25519.pub"
```

**Tell the human:** "Add this SSH key to your GitHub account at https://github.com/settings/ssh/new"

## Step 11: Set up local DNS (optional, macOS)

To resolve `*.vm` to the VM's Tailscale IP on the human's Mac:

```bash
brew install dnsmasq
echo "address=/.vm/$TAILSCALE_IP" > $(brew --prefix)/etc/dnsmasq.d/vm.conf
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/vm
sudo brew services start dnsmasq
```

Then `ssh <username>@<hostname>.vm` works.

## Troubleshooting

### VM doesn't boot (no serial output)
- Secure Boot is probably enabled. Delete the VM and recreate with `--security-type Standard`.

### VM boots but SSH times out
- Network issue. Check serial console for `dhcpcd` errors (this script uses systemd-networkd which works, but if someone manually changes to dhcpcd it will break).

### "prohibited by secure boot policy" in boot log
- Secure Boot is enabled. Run: `az vm update -g $RG -n $VM --enable-secure-boot false` then restart.

### Tailscale goes offline after nixos-rebuild
- Normal. Tailscale restarts during rebuild. It reconnects within ~60 seconds. If not, restart the VM: `az vm restart -g $RG -n $VM`.

## Architecture Notes

- **Boot chain**: UEFI → Ubuntu shimx64.efi → GRUB → NixOS kernel
- **Networking**: systemd-networkd (NOT dhcpcd — it fails on Hyper-V)
- **Docker data**: stored on /home partition (data disk if attached)
- **Memory**: zram swap (25% RAM, zstd) + earlyoom (kills at 5% free)
- **NixOS channel**: 24.11 stable (claude-code needs nixpkgs-unstable via nix-env)
