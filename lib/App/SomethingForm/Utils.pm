package App::SomethingForm::Utils;

use strict;
use warnings;

use Crypt::CBC;
use Crypt::Cipher::AES;
use Crypt::Mac::HMAC;
use Encode qw(encode_utf8);
use JSON::MaybeXS;
use MIME::Base64;
 
BEGIN {
    our @EXPORT_OK = qw(
        decrypt_form_metadata
        encrypt_form_metadata
        form_signature
    );

    require Exporter;
    *import = \&Exporter::import;
}

=func form_signature

Calculates the SHA-256 signature for the provided form specification.

Arguments:

=begin :list

* C<$form_spec_json> - form specification (JSON string)
* C<$key> - secret key

=end :list

Returns the base64-encoded signature.

=cut

sub form_signature {
    my ($form_spec_json, $key) = @_;

    # Parse and re-encode JSON data in canonical mode to ensure keys have
    # the same (alphanumerical) order
    my $json = JSON::MaybeXS->new({ canonical => 1 });
    $form_spec_json = $json->encode($json->decode($form_spec_json));

    return Crypt::Mac::HMAC::hmac_b64('SHA256', $key, encode_utf8($form_spec_json));
}

=func encrypt_form_metadata

Encrypts (using AES) the provided form metadata.

Arguments:

=begin :list

* C<$form_metadata> - form metadata (hashref)
* C<$key> - secret key

=end :list

Returns the base64-encoded ciphertext.

=cut

sub encrypt_form_metadata {
    my ($form_metadata, $key) = @_;

    my $json = JSON::MaybeXS->new({ canonical => 1 });
    my $form_metadata_json = $json->encode($form_metadata);

    my $cbc = Crypt::CBC->new(
        -cipher => 'Cipher::AES',
        -key    => $key
    );

    return encode_base64($cbc->encrypt($form_metadata_json), '');
}

=func encrypt_form_metadata

Decrypts (using AES) the provided encrypted form metadata.

Arguments:

=begin :list

* C<$data> - encrypted data (base64-encoded)
* C<$key> - secret key

=end :list

Returns a hashref of data.

=cut

sub decrypt_form_metadata {
    my ($data, $key) = @_;

    my $json = JSON::MaybeXS->new({ canonical => 1 });

    my $cbc = Crypt::CBC->new(
        -cipher => 'Cipher::AES',
        -key    => $key
    );

    return $json->decode($cbc->decrypt(decode_base64($data)));
}

1;
