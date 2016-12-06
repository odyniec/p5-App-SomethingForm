package App::SomethingForm;

# ABSTRACT: Dancer app that receives data from HTML forms and emails it

# VERSION

use utf8;

use Dancer2;
use Dancer2::Plugin::Email;
use Encode qw(decode encode);

get '/' => sub {
    template 'index';
};

post '/somethingform' => sub {
    my $data = params;

    content_type 'application/json';

    header 'access-control-allow-origin' => '*';

    my $config = config;

    my $data = from_json(request->body);

    # $data is an array of hashes that represent fieldsets, each containing an
    # array of hashes representing fields, e.g.:
    #
    # [
    #     {
    #         'Personal information' => [
    #             { name => 'First name', value => 'Mikey' },
    #             { name => 'Last name', value => 'Walsh' }
    #         ],
    #         'Contact' => [
    #             { name => 'E-mail address', value => 'mikey@example.com' }
    #         ]
    #     }
    # ]

    if (my $form_id = get_value($data, 'somethingform_form_id')) {
        $config = { %$config, %{ config->{forms}{$form_id} } };
    }

    # Build notification contents
    my $notification_text;

    while (my (undef, $fieldset) = each @$data) {
        my $part = '';

        my ($name, $fields) = each %$fieldset;

        if ($name =~ /\S/) {
            $part .= "$name\n" . ('-' x length $name) . "\n";
        }

        map { $part .= "$_->{name}: $_->{value}\n" }
            grep { $_->{name} !~ /^somethingform_/ } @$fields;

        if ($part =~ /./) {
            $notification_text .= $notification_text ? "\n$part" : $part;
        }
    }

    my $subject = Encode::encode("MIME-Q",
        replace_fields($config->{notification_subject} //
            'New message from %somethingform_form_id% form', $data));

    email {
        from    => $config->{notification_from},
        to      => $config->{notification_to},
        subject => $subject,
        body    => encode('UTF-8', $notification_text),
    };

    status '200';
    return to_json({ msg => 'Message sent' });
};

post '/somethingform/setup' => sub {
    content_type 'application/json';

    header 'access-control-allow-origin' => '*';

    my $data = from_json(request->body);

    my $form_signature = App::SomethingForm::Utils::form_signature(
        $data->{form_spec}, config->{somethingform}{secret_key});

    my $form_metadata = encrypt_form_metadata($data->{form_metadata},
        config->{somethingform}{secret_key});

    return to_json({
        form_signature  => $form_signature,
        form_metadata   => $form_metadata
    });
};

sub get_value {
    my ($data, $name) = @_;

    my ($item) = grep { $_->{name} eq $name }
        map { @$_ } map { values %$_ } @$data;

    return $item->{value} if defined $item;
    return;
}

sub replace_fields {
    my ($text, $data) = @_;

    $text =~ s/%([^%]+)%/get_value($data, $1) || ''/egms;

    return $text;
}

true;
