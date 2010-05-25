use Module::Build;

Module::Build->new(
    module_name => 'Calorific',
    license => 'perl',
    dist_author => 'Pete Keen <pete@bugsplat.info>',
    license => 'perl',
    requires => {
        'DateTime::Format::Natural' => '0.85',
        'File::Slurp'               => '9999.13',
        'Mouse'                     => '0.52',
        'MouseX::NativeTraits'      => '0.002',
        'Perl6::Form'               => '0.04',
        'YAML::XS'                  => '0.32',
    }
)->create_build_script();
