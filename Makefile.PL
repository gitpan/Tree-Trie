use inc::Module::Install;

name 'Tree-Trie';
all_from 'Trie.pm';

build_requires('Test::Pod');
build_requires('Test::Pod::Coverage');

auto_install;
WriteAll;
