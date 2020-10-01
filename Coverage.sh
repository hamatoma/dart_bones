#! /bin/sh
if [ $(id -u) = 0 ]; then
  echo "+++ not working as root"
else
flutter test --coverage
rm -Rf coverage/html/*
genhtml --show-details --output-directory=coverage/html coverage/lcov.info
fi
