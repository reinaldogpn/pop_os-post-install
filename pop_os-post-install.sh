#!/usr/bin/env bash
#
# pop_os-post-install.sh - Faz a pós configuração do Pop!_OS 22.04 LTS.
# ------------------------------------------------------------------------ #
# O QUE ELE FAZ?
# Esse script instalar os programas que utilizo após a instalação do Pop!_OS, faz upgrade
# e limpeza do sistema. É de fácil expensão (mudar variáveis).
#
# COMO USAR?
#   - Dar permissões ao arquivo script: chmod +x nome_do_arquivo ;
#   $ ./pop_os-post-install.sh
#
# DICA:
#   - Para descompactar arquivos .tar.gz use:
#   tar -zxvf nome_do_arquivo.tar.gz 
# ------------------------------------------------------------------------ #
# Changelog:
#
#   v1.0 19/06/2022, reinaldogpn:
#     - Primeira versão.
# ------------------------------------------------------------------------ #
# Extras:
# 
# Link para download Foxit PDF Reader:
# - https://cdn01.foxitsoftware.com/pub/foxit/reader/desktop/linux/2.x/2.4/en_us/FoxitReader.enu.setup.2.4.4.0911.x64.run.tar.gz
#
# Link para download Etcher (AppImage):
# - https://github.com/balena-io/etcher/releases/download/v1.7.9/balena-etcher-electron-1.7.9-linux-x64.zip?d_id=0d82ff50-dda3-4548-960a-8fa042ff69a4R
#
# Deezer Player (Unofficial):
# - sudo snap install deezer-unofficial-player
#
# Fix for LoL "Critical Error":
# - sudo sysctl -w abi.vsyscall32=0 && lutris
#
# Disable 2K Louncher on Steam's Civilization VI init options:
# - eval $( echo "%command%" | sed "s/2KLauncher\/LauncherPatcher.exe'.*/Base\/Binaries\/Win64Steam\/CivilizationVI.exe'/" )
#
# Steam's Counter Strike Global Offensive init options:
# - -tickrate 128 +fps_max 0 -nojoy -novid -fullscreen -r_emulate_gl -limitvsconst -forcenovsync -softparticlesdefaultoff +mat_queue_mode 2 +mat_disable_fancy_blending 1 +r_dynamic 0 -refresh 75
#
# ---------------------------- VARIÁVEIS --------------------------------- #

# ***** PROGRAMAS *****
PACOTES_APT=(
  calibre
  chrome-gnome-shell
  code
  dconf-editor
  discord
  flatpak
  gnome-software
  gnome-software-plugin-flatpak
  gnome-sushi
  gnome-tweaks
  gnome-shell-extension-dash-to-dock-pop
  codeblocks
  gimp
  inkscape
  keepassx
  liballegro5-dev
  libvulkan1
  libvulkan1:i386
  lutris
  neofetch
  qbittorrent
  ubuntu-restricted-extras
  virtualbox
  vlc
  steam-installer
  steam-devices
  steam:i386
  wine
)

PACOTES_FLATPAK=(
  app.ytmdesktop.ytmdesktop
  com.google.Chrome
  io.github.mimbrero.WhatsAppDesktop
  org.onlyoffice.desktopeditors
# com.mojang.Minecraft 			    # Minecraft
)

# ***** CORES *****
AMARELO='\e[1;93m'
VERMELHO='\e[1;91m'
VERDE='\e[1;92m'
SEM_COR='\e[0m'

# ***** EXTRA *****
FILE="/home/$USER/.config/gtk-3.0/bookmarks"

# ------------------------------ TESTES ---------------------------------- #
# Internet conectando?
if ! ping -c 1 8.8.8.8 -q &> /dev/null; then
  echo -e "${VERMELHO}[ERROR] - Seu computador não tem conexão com a internet. Verifique os cabos e o modem.${SEM_COR}"
  exit 1
else
  echo -e "${VERDE}[INFO] - Conexão com a internet funcionando normalmente.${SEM_COR}"
fi

# wget está instalado?
if [[ ! -x $(which wget) ]]; then
  echo -e "${VERMELHO}[ERROR] - O programa wget não está instalado.${SEM_COR}"
  echo -e "${AMARELO}[INFO] - Instalando wget ...${SEM_COR}"
  sudo apt install wget -y &> /dev/null
else
  echo -e "${VERDE}[INFO] - O programa wget já está instalado.${SEM_COR}"
fi

# ------------------------------ FUNÇÕES --------------------------------- #
remover_locks() 
{
  echo -e "${AMARELO}[INFO] - Removendo locks...${SEM_COR}"
  sudo rm /var/lib/dpkg/lock-frontend &> /dev/null
  sudo rm /var/cache/apt/archives/lock &> /dev/null
  echo -e "${VERDE}[INFO] - Locks removidos.${SEM_COR}"
}

adicionar_arquitetura_i386() 
{
  echo -e "${AMARELO}[INFO] - Adicionando arquitetura i386...${SEM_COR}"
  sudo dpkg --add-architecture i386 &> /dev/null
}

atualizar_repositorios()
{
  echo -e "${AMARELO}[INFO] - Atualizando repositórios ...${SEM_COR}"
  sudo apt update -y &> /dev/null
}

instalar_pacotes_apt()
{
  echo -e "${AMARELO}[INFO] - Instalando pacotes apt ...${SEM_COR}"
  for pacote in ${PACOTES_APT[@]}; do
    if ! dpkg -l | grep -q $pacote; then
      echo -e "${AMARELO}[INFO] - Instalando o pacote $pacote ...${SEM_COR}"
      sudo apt install $pacote -y &> /dev/null
      if dpkg -l | grep -q $pacote; then
        echo -e "${VERDE}[INFO] - O pacote $pacote foi instalado.${SEM_COR}"
      else
        echo -e "${VERMELHO}[ERROR] - O pacote $pacote não foi instalado.${SEM_COR}"
      fi
    else
      echo -e "${VERDE}[INFO] - O pacote $pacote já está instalado.${SEM_COR}"
    fi
  done
}

instalar_dependencias_allegro()
{
  echo -e "${AMARELO}[INFO] - Instalando dependências do Allegro ...${SEM_COR}"
  sudo apt install -y cmake g++ freeglut3-dev libxcursor-dev libpng-dev libjpeg-dev libfreetype6-dev libgtk2.0-dev libasound2-dev libpulse-dev libopenal-dev libflac-dev libdumb1-dev libvorbis-dev libphysfs-dev &> /dev/null
}

adicionar_repositorios_flatpak()
{
  echo -e "${AMARELO}[INFO] - Adicionando repositórios flatpak com o remote-add...${SEM_COR}"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  echo -e "${VERDE}[INFO] - Nada mais a adicionar.${SEM_COR}"
}

instalar_pacotes_flatpak()
{
  echo -e "${AMARELO}[INFO] - Instalando pacotes flatpak...${SEM_COR}"
  for pacote in ${PACOTES_FLATPAK[@]}; do
    if ! flatpak list | grep -q $pacote; then
      echo -e "${AMARELO}[INFO] - Instalando o pacote $pacote...${SEM_COR}"
      sudo flatpak install -y flathub $pacote &> /dev/null
      if flatpak list | grep -q $pacote; then
        echo -e "${VERDE}[INFO] - O pacote $pacote foi instalado.${SEM_COR}"
      else
        echo -e "${VERMELHO}[ERROR] - O pacote $pacote não foi instalado.${SEM_COR}"
      fi
    else
      echo -e "${VERDE}[INFO] - O pacote $pacote já está instalado.${SEM_COR}"
    fi
  done
}

instalar_driver_TPLinkT2UPlus()
{
#  (Instalação opcional) Driver do adaptador wireless TPLink Archer T2U Plus
  echo -e "${AMARELO}[INFO] - Instalando driver wi-fi TPLink...${SEM_COR}"
  sudo apt install -y dkms git &> /dev/null
  sudo apt install -y build-essential libelf-dev linux-headers-$(uname -r) &> /dev/null
  mkdir $HOME/Downloads/rtl8812au/
  git clone https://github.com/aircrack-ng/rtl8812au.git $HOME/Downloads/rtl8812au/ &> /dev/null
  cd $HOME/Downloads/rtl8812au/
  sudo make dkms_install &> /dev/null
#  se a instalação for abortada, executar o comando: "sudo dkms remove 8812au/5.6.4.2_35491.20191025 --all"
  echo -e "${VERDE}[INFO] - Driver wi-fi instalado!${SEM_COR}"
}

extra_config()
{
  echo -e "${AMARELO}[INFO] - Criando diretórios pessoais...${SEM_COR}"
  mkdir /home/$USER/Projetos
  #Adiciona atalhos ao Nautilus
  if test -f "$FILE"; then
      echo -e "${VERDE}[INFO] - $FILE já existe.${SEM_COR}"
  else
      echo -e "${AMARELO}[INFO] - $FILE não existe. Criando...${SEM_COR}"
      touch /home/$USER/.config/gkt-3.0/bookmarks
  fi
  echo "file:///home/$USER/Projetos 🔵 Projetos" >> $FILE
}

upgrade_e_limpeza_sistema()
{
  echo -e "${AMARELO}[INFO] - Fazendo upgrade e limpeza do sistema ...${SEM_COR}"
  sudo apt dist-upgrade -y &> /dev/null
  sudo apt autoclean &> /dev/null
  sudo apt autoremove -y &> /dev/null
  sudo flatpak update -y &> /dev/null
  sudo snap refresh &> /dev/null
  rm -rf $HOME/Downloads/rtl8812au &> /dev/null
  neofetch
  echo -e "${VERDE}[INFO] - Configuração concluída!${SEM_COR}"
  echo -e "${AMARELO}[INFO] - Reinicialização necessária, deseja reiniciar agora? [S/n]:${SEM_COR}"
  read opcao
  [ $opcao = "s" ] || [ $opcao = "S" ] && echo -e "${AMARELO}[INFO] - Fim do script! Reiniciando agora...${SEM_COR}" && reboot
  echo -e "${VERDE}[INFO] - Fim do script! ${SEM_COR}"
}

# ----------------------------- EXECUÇÃO --------------------------------- #
remover_locks
adicionar_arquitetura_i386
atualizar_repositorios
instalar_pacotes_apt
instalar_dependencias_allegro
adicionar_repositorios_flatpak
instalar_pacotes_flatpak
instalar_driver_TPLinkT2UPlus
extra_config
upgrade_e_limpeza_sistema
