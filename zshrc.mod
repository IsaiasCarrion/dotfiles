# ~/.zshrc - Carga condicional de herramientas

# Zinit
if [[ -f "$HOME/.zinit/bin/zinit.zsh" ]]; then
  source "$HOME/.zinit/bin/zinit.zsh"
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zdharma-continuum/fast-syntax-highlighting
else
  echo "[.zshrc] ⚠️ Zinit no encontrado."
fi

# Starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  echo "[.zshrc] ⚠️ Starship no encontrado."
fi

# Confirmación de carga
echo "[.zshrc] ✅ cargado correctamente"