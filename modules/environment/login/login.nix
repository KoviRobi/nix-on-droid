# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, writeScript }:

let
  inherit (config.build) installationDir;
in

writeScript "login" ''
  #!/system/bin/sh
  set -e

  export USER="${config.user.userName}"
  export PROOT_TMP_DIR=${installationDir}/tmp
  export PROOT_L2S_DIR=${installationDir}/.l2s

  if ! /system/bin/pgrep proot-static > /dev/null; then
    if test -e ${installationDir}/bin/.proot-static.new; then
      echo "Install new proot-static..."
      /system/bin/mv ${installationDir}/bin/.proot-static.new ${installationDir}/bin/proot-static
    fi

    if test -e ${installationDir}/usr/lib/.login-inner.new; then
      echo "Install new login-inner..."
      /system/bin/mv ${installationDir}/usr/lib/.login-inner.new ${installationDir}/usr/lib/login-inner
    fi
  fi

  exec ${installationDir}/bin/proot-static \
    -b ${installationDir}/nix:/nix \
    -b ${installationDir}/bin:/bin \
    -b ${installationDir}/etc:/etc \
    -b ${installationDir}/tmp:/tmp \
    -b ${installationDir}/usr:/usr \
    -b /:/android \
    --link2symlink \
    ${installationDir}/bin/sh ${installationDir}/usr/lib/login-inner "$@"
''
