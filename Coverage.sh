#! /bin/sh
flutter test --coverage
rm -Rf coverage/html/*
genhtml --show-details --output-directory=coverage/html coverage/lcov.info
