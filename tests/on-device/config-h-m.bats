# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'using home-manager works' {
  # start from a known baseline
  switch_to_default_config
  assert_command vi
  assert_no_command dash
  ! [[ -e ~/.config/example ]]

  nix-channel --add https://github.com/rycee/home-manager/archive/release-21.11.tar.gz home-manager
  nix-channel --update
  cp "$ON_DEVICE_TESTS_DIR/config-h-m.nix" ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch

  # test config file
  [[ -e ~/.config/example ]]
  [[ "$(cat ~/.config/example)" == 'example config' ]]

  # test common commands presence
  assert_command nix-on-droid nix-shell bash

  # test that vi has disappeared
  assert_no_command vi

  # test dash has appeared and works
  assert_command dash
  run dash -c 'echo success; exit 42'
  [[ "$output" == success ]]
  [[ "$status" == 42 ]]

  switch_to_default_config
}
