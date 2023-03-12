# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, runCommand, gnutar, bootstrap }:

runCommand "bootstrap-zip" { } ''
  mkdir $out
  cd ${bootstrap}
  ${gnutar}/bin/tar czf $out/bootstrap-${config.build.arch}.tar.gz ./* ./.l2s
''
