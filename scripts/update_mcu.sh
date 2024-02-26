#!/usr/bin/env bash

###########################################################################################
### Please set the following paths accordingly.                                         ###
###########################################################################################

### Path to your Klipper folder, by default that is '~/klipper'
klipper_folder=~/klipper

### Path to your Katapult folder, by default that is '~/katapult'
katapult_folder=~/katapult

### Path to your mcu config folder
config_folder=~/printer_data/config/scripts/mcu_configs

### Path to your firmware folder, by default, will be '~/firmware'
firmware_folder=~/firmware

###########################################################################################
### List your MCUs in the following format:                                             ###
###                                                                                     ###
### declare -A mcu0=( # The number after mcu must go in order starting at 0             ###
###    [type]='kraken' # Required                                                       ###
###    [can_address]='5cbcb7c7dc7f' # Optional                                          ###
###    [usb_address]='usb-CanBoot_stm32f446xx_4A0021000651303431333234-if00' # Optional ###
### )                                                                                   ###
###########################################################################################

declare -A mcu0=(
    [type]='sb2209'
    [can_address]='a6dbb36fd844'
)

declare -A mcu1=(
    [type]='mmu'
    [can_address]='1e67a8e2112e'
)

declare -A mcu2=(
    [type]='kraken'
    [can_address]='5cbcb7c7dc7f'
    [usb_address]='usb-CanBoot_stm32f446xx_4A0021000651303431333234-if00'
)

declare -A mcu3=(
    [type]='rpi'
)

###########################################################################################
########################### !!! DO NOT EDIT BELOW THIS LINE !!! ###########################
###########################################################################################

declare -n mcu

sudo service klipper stop

cd $klipper_folder
git pull --autostash

for current in ${!mcu}; do
  cp -f "${config_folder}/config.${current[type]}" $klipper_folder

  read -p "${current[type]} firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

  make clean KCONFIG_CONFIG="config.${current[type]}"
  make menuconfig KCONFIG_CONFIG="config.${current[type]}"

  if [[ -n "${current[can_address]}" ]]; then
    make KCONFIG_CONFIG="config.${current[type]}"
    mv "$(klipper_folder)/out/klipper.bin" ${current[type]}/${current[type]}_klipper.bin

    read -p "${current[type]} firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

    python3 "$(katapult_folder)/scripts/flash_can.py" -i can0 -u "${current[can_address]}" -f "$(firmware_folder)/${current[type]}_klipper.bin"

    if [[ -n "${current[usb_address]}" ]]; then
      read -p "We intentionally caused an error on the ${current[type]} to boot into the bootloader. Please ignore and Press [Enter] to continue flashing, or [Ctrl+C] to abort"

      python3 "$(katapult_folder)/scripts/flash_can.py" -d "/dev/serial/by-id/${current[usb_address]}" -f "$(firmware_folder)/${current[type]}_klipper.bin"
    fi

    read -p "${current[type]} firmware flashed, please check above for any errors. Press [Enter] to continue building, or [Ctrl+C] to abort"
  elif [[ "${current[type]}" == "rpi" ]]; then
    make flash KCONFIG_CONFIG="config.${current[type]}"

    read -p "${current[type]} firmware flashed, please check above for any errors. Press [Enter] to continue building, or [Ctrl+C] to abort"
  else
    make KCONFIG_CONFIG="config.${current[type]}"
    mv "$(klipper_folder)/out/klipper.bin" $(firmware_folder)/${current[type]}_klipper.bin

    read -p "${current[type]} firmware built, please check above for any errors. Firmware is stored here: $(firmware_folder)/${current[type]}_klipper.bin and you will need to install it per your board type manually. Press [Enter] to continue, or [Ctrl+C] to abort"
  fi

  cp -f "$(klipper_folder)/config.${current[type]}" $config_folder
done

sudo service klipper start
