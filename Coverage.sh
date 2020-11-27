#! /bin/sh
if [ $(id -u) = 0 ]; then
  echo "+++ not working as root"
else
  file=test/coverage_helper_test.dart
  PACKAGE=dart_bones
  echo "// Helper file to make coverage work for all dart files\n" > $file
  echo "// ignore_for_file: unused_import" >> $file
  find lib -not -name '*.g.dart' -name '*.dart' | grep -v 'generated_plugin_registrant' | cut -c4- \
    | awk -v package=$PACKAGE '{printf "import '\''package:%s%s'\'';\n", package, $1}' >> $file
  echo "\nvoid main(){}" >> $file
  flutter test --coverage
  rm -Rf coverage/html/*
  genhtml --show-details --output-directory=coverage/html coverage/lcov.info
fi
