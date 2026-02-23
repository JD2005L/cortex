#!/bin/bash
# OpenCortex Vault — Encrypted key-value store for sensitive data
# Uses GPG symmetric encryption (AES-256). Passphrase stored at .vault/.passphrase (mode 600).
#
# Usage:
#   vault.sh init              — Set up vault (creates GPG key + encrypted store)
#   vault.sh set <key> <value> — Store a secret
#   vault.sh get <key>         — Retrieve a secret
#   vault.sh list              — List stored keys (not values)
#   vault.sh delete <key>      — Remove a secret
#   vault.sh rotate            — Rotate passphrase (re-encrypts all secrets)

set -euo pipefail

WORKSPACE="${CLAWD_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
VAULT_DIR="$WORKSPACE/.vault"
VAULT_FILE="$VAULT_DIR/secrets.gpg"
VAULT_PASS="$VAULT_DIR/.passphrase"

_ensure_vault() {
  if [ ! -f "$VAULT_FILE" ] || [ ! -f "$VAULT_PASS" ]; then
    echo "Vault not initialized. Run: vault.sh init"
    exit 1
  fi
}

_decrypt() {
  gpg --batch --yes --passphrase-file "$VAULT_PASS" --quiet --decrypt "$VAULT_FILE" 2>/dev/null
}

_encrypt() {
  local content="$1"
  echo "$content" | gpg --batch --yes --passphrase-file "$VAULT_PASS" --quiet --symmetric --cipher-algo AES256 --output "$VAULT_FILE" 2>/dev/null
}

case "${1:-help}" in
  init)
    mkdir -p "$VAULT_DIR"
    chmod 700 "$VAULT_DIR"
    
    if [ -f "$VAULT_PASS" ]; then
      echo "Vault already initialized at $VAULT_DIR"
      exit 0
    fi
    
    # Generate random passphrase
    openssl rand -base64 32 > "$VAULT_PASS"
    chmod 600 "$VAULT_PASS"
    
    # Create empty vault
    _encrypt ""
    chmod 600 "$VAULT_FILE"
    
    echo "✅ Vault initialized at $VAULT_DIR"
    echo "   Passphrase: $VAULT_PASS (600 perms, never committed)"
    ;;
    
  set)
    _ensure_vault
    KEY="${2:-}"
    VALUE="${3:-}"
    
    if [ -z "$KEY" ] || [ -z "$VALUE" ]; then
      echo "Usage: vault.sh set <key> <value>"
      exit 1
    fi

    # Validate key name: must match ^[a-zA-Z_][a-zA-Z0-9_]*$
    if ! echo "$KEY" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*$'; then
      echo "❌ Invalid key name: '$KEY'"
      echo "   Key must start with a letter or underscore, and contain only"
      echo "   letters, digits, and underscores (^[a-zA-Z_][a-zA-Z0-9_]*\$)."
      echo "   This prevents keys with '=' or spaces from breaking storage."
      exit 1
    fi

    # Load existing, remove old key if exists, add new
    CONTENT=$(_decrypt | grep -v "^${KEY}=" || true)
    CONTENT="${CONTENT}
${KEY}=${VALUE}"
    _encrypt "$CONTENT"
    
    echo "✅ Stored: $KEY"
    ;;
    
  get)
    _ensure_vault
    KEY="${2:-}"
    
    if [ -z "$KEY" ]; then
      echo "Usage: vault.sh get <key>"
      exit 1
    fi
    
    VALUE=$(_decrypt | grep "^${KEY}=" | head -1 | cut -d= -f2-)
    
    if [ -z "$VALUE" ]; then
      echo "Key not found: $KEY"
      exit 1
    fi
    
    echo "$VALUE"
    ;;
    
  list)
    _ensure_vault
    _decrypt | grep -v "^$" | cut -d= -f1 | sort
    ;;
    
  delete)
    _ensure_vault
    KEY="${2:-}"
    
    if [ -z "$KEY" ]; then
      echo "Usage: vault.sh delete <key>"
      exit 1
    fi
    
    CONTENT=$(_decrypt | grep -v "^${KEY}=" || true)
    _encrypt "$CONTENT"
    
    echo "✅ Deleted: $KEY"
    ;;
    
  rotate)
    _ensure_vault
    echo "🔄 Rotating vault passphrase..."

    # Decrypt all secrets with current passphrase
    CONTENT=$(_decrypt)

    # Generate a new passphrase (same method as init)
    NEW_PASS=$(openssl rand -base64 32)

    # Update the passphrase file
    echo "$NEW_PASS" > "$VAULT_PASS"
    chmod 600 "$VAULT_PASS"

    # Re-encrypt all secrets with the new passphrase
    _encrypt "$CONTENT"

    echo "✅ Passphrase rotated successfully."
    echo "   All secrets have been re-encrypted with the new passphrase."
    echo "   Old passphrase is no longer valid."
    ;;

  help|*)
    echo "OpenCortex Vault — Encrypted secret storage"
    echo ""
    echo "Commands:"
    echo "  init              Set up vault"
    echo "  set <key> <value> Store a secret"
    echo "  get <key>         Retrieve a secret"
    echo "  list              List keys (not values)"
    echo "  delete <key>      Remove a secret"
    echo "  rotate            Rotate passphrase (re-encrypts all secrets)"
    echo ""
    echo "Secrets encrypted at rest via GPG symmetric encryption (AES-256). The symmetric passphrase is stored in .vault/.passphrase with 600 permissions."
    echo "Reference in TOOLS.md: 'password: vault:my_key_name'"
    ;;
esac
