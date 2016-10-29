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

    $data = from_json(request->body);

    if (my $form_id = get_field($data, 'somethingform_form_id')) {
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
            'New message from %somethingform_form_id% form'));

    email {
        from    => $config->{notification_from},
        to      => $config->{notification_to},
        subject => $subject,
        body    => encode('UTF-8', $notification_text),
    };

    status '200';
    return to_json({ msg => 'Message sent' });
};

{
    my $data_by_key;

    sub get_field {
        my ($data, $name) = @_;

        $data_by_key //= {
            map { $_->{name} => $_->{value} }
                map { @$_ }
                    map { values %$_ } @$data
        };

        return exists $data_by_key->{$name} ? $data_by_key->{$name} : undef;
    }

    sub replace_fields {
        my ($text) = @_;

        $text =~ s/%([^%]+)%/$data_by_key->{$1} || ''/egms;

        return $text;
    }
}

true;
