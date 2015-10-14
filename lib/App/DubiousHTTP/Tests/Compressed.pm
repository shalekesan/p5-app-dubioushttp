use strict;
use warnings;
package App::DubiousHTTP::Tests::Compressed;
use App::DubiousHTTP::Tests::Common;
use Compress::Raw::Zlib;
use Compress::Raw::Lzma;

SETUP( 
    'compressed',
    "Variations on content compression",
    <<'DESC',
Compression of Content is usueally done with a Content-Encoding header and a
value of 'gzip' (RFC1952) or 'deflate' (RFC1951). Most browsers additionally 
accept RFC1950 compressed data (zlib) if 'deflate' is specified.
Some browsers also support compression with the Transfer-Encoding header, 
which is actually specified in the HTTP RFC, but most browsers don't.
Some browsers just guess the encoding, e.g. accept gzip even if deflate is
specified.
And some browsers accept x-gzip and x-deflate specifications, and some even
specifications like "x gzip" or "gzip x".
Most browsers accept multiple content-encoding headers, even if it does not
make much sense to compress content twice with the same encoding.
DESC

    # ------------------------- Tests ----------------------------------------

    # these should be fine
    [ 'VALID: correct compressed requests' ],
    [ SHOULDBE_VALID, 'ce:gzip;gzip' => 'content-encoding gzip, served gzipped'],
    [ VALID, 'ce:gzip;gzip2p' => 'content-encoding gzip, served gzipped with 2 compressed blocks'],
    [ UNCOMMON_VALID, 'ce:x-gzip;gzip' => 'content-encoding "x-gzip", served gzipped'], # not IE11
    [ SHOULDBE_VALID, 'ce:deflate;deflate' => 'content-encoding deflate, served with deflate'],
    [ VALID, 'ce:deflate;deflate2p' => 'content-encoding deflate, served with deflate with 2 compressed blocks'],
    [ VALID, 'ce:deFLaTe;deflate' => 'content-encoding deflate mixed case, served with deflate'],

    [ 'VALID: lzma (supported by at least Opera)' ],
    [ UNCOMMON_VALID, 'ce:lzma;lzma1' => 'content-encoding lzma, lzma1 (lzma_alone) encoded'],

    # these might be strange/unsupported
    [ 'VALID: less common but valid requests' ],
    [ UNCOMMON_INVALID, 'ce:deflate;deflate-raw' => 'content-encoding deflate, served with RFC1950 style deflate (zlib)'],
    [ UNCOMMON_INVALID, 'ce:deflate;deflate-raw2p' => 'content-encoding deflate, served with RFC1950 style deflate (zlib) with 2 compressed blocks'],
    [ UNCOMMON_VALID, 'ce:nl-gzip;gzip' => 'content-encoding gzip but with continuation line, served gzipped'],
    [ UNCOMMON_VALID, 'ce:nl-deflate;deflate' => 'content-encoding deflate but with continuation line, served with deflate'],
    [ UNCOMMON_VALID, 'ce:nl-nl-deflate;deflate' => 'content-encoding deflate but with double continuation line, served with deflate'],
    [ UNCOMMON_VALID, 'ce:deflate,;deflate' => 'content-encoding "deflate,", served with deflate'],
    [ UNCOMMON_VALID, 'ce:deflate-nl-,;deflate' => 'content-encoding "deflate<nl> ,", served with deflate'],
    [ UNCOMMON_VALID, 'ce:deflate-nl-,-nl-;deflate' => 'content-encoding "deflate<nl> ,<nl> ", served with deflate'],

    # These should be fine according to RFC, but are not supported in the browsers
    # Thus treat is as problem if they get supported.
    [ 'INVALID: transfer-encoding with compression should not be supported' ],
    [ INVALID, 'te:gzip;gzip' => 'transfer-encoding gzip, served gzipped'],
    [ INVALID, 'te:deflate;deflate' => 'transfer-encoding deflate, served with deflate'],
    [ INVALID, 'te:gzip;ce:gzip;gzip;gzip' => 'transfer-encoding and content-encoding gzip, gzipped twice'],

    # double encodings
    [ 'VALID: double encodings' ],
    [ UNCOMMON_VALID, 'ce:gzip;ce:gzip;gzip;gzip' => 'double content-encoding header gzip, served twice gzipped'],
    [ UNCOMMON_VALID, 'ce:gzip,gzip;gzip;gzip' => 'single content-encoding header "gzip,gzip", served twice gzipped'],
    [ UNCOMMON_VALID, 'ce:deflate;ce:deflate;deflate;deflate' => 'double content-encoding header deflate, compressed twice with deflate'],
    [ UNCOMMON_VALID, 'ce:deflate,deflate;deflate;deflate' => 'single content-encoding header "deflate,deflate", compressed twice with deflate'],
    [ UNCOMMON_VALID, 'ce:deflate-nl-,-nl-deflate;deflate;deflate' => 'single content-encoding header "deflate<nl> ,<nl> deflate", compressed twice with deflate'],
    [ UNCOMMON_VALID, 'ce:deflate-nl-,-nl-deflate-nl-;deflate;deflate' => 'single content-encoding header "deflate<nl> ,<nl> deflate<nl> ", compressed twice with deflate'],

    [ UNCOMMON_VALID, 'ce:gzip;ce:deflate;gzip;deflate' => 'content-encoding header for gzip and deflate, content compressed in this order'],
    [ UNCOMMON_VALID, 'ce:gzip,deflate;gzip;deflate' => 'single content-encoding "gzip,deflate", content compressed in this order'],
    [ UNCOMMON_VALID, 'ce:deflate;ce:gzip;deflate;gzip' => 'content-encoding header for deflate and gzip, content compressed in this order'],
    [ UNCOMMON_VALID, 'ce:deflate,gzip;deflate;gzip' => 'single content-encoding header "deflate,gzip", content compressed in this order'],

    # according to RFC2616 identity SHOULD only be used in Accept-Encoding, not Content-Encoding
    [ 'INVALID: using "content-encoding: identity"' ],
    [ UNCOMMON_INVALID, 'ce:identity', '"content-encoding:identity", served without encoding' ],
    [ UNCOMMON_INVALID, 'ce:identity;ce:identity', 'twice "content-encoding:identity", served without encoding' ],
    [ UNCOMMON_INVALID, 'ce:identity,identity', '"content-encoding:identity,identity", served without encoding' ],
    [ UNCOMMON_INVALID, 'ce:identity;ce:gzip;gzip' => 'content-encoding header for identity and gzip, compressed with gzip'],
    [ UNCOMMON_INVALID, 'ce:identity,gzip;gzip' => 'single content-encoding "identity,gzip", compressed with gzip'],
    [ UNCOMMON_INVALID, 'ce:gzip;ce:identity;gzip' => 'content-encoding header for gzip and identity, compressed with gzip'],
    [ UNCOMMON_INVALID, 'ce:gzip,identity;gzip' => 'single content-encoding header "gzip,identity", compressed with gzip'],

    [ UNCOMMON_INVALID, 'ce:identity;ce:deflate;deflate' => 'content-encoding header for identity and deflate, compressed with deflate'],
    [ UNCOMMON_INVALID, 'ce:identity,deflate;deflate' => 'single content-encoding "identity,deflate", compressed with deflate'],
    [ UNCOMMON_INVALID, 'ce:deflate;ce:identity;deflate' => 'content-encoding header for deflate and identity, compressed with deflate'],
    [ UNCOMMON_INVALID, 'ce:deflate,identity;deflate' => 'single content-encoding header "deflate,identity", compressed with deflate'],

    # triple encodings
    [ 'VALID: triple encodings' ],
    [ UNCOMMON_VALID, 'ce:gzip;ce:deflate;ce:gzip;gzip;deflate;gzip' => 'served gzip + deflate + gzip, separate content-encoding header'],
    [ UNCOMMON_VALID, 'ce:gzip,deflate,gzip;gzip;deflate;gzip' => 'served gzip + deflate + gzip, single content-encoding header'],
    [ UNCOMMON_VALID, 'ce:gzip,deflate;ce:gzip;gzip;deflate;gzip' => 'served gzip + deflate + gzip, two content-encoding headers'],
    [ UNCOMMON_VALID, 'ce:deflate;ce:gzip;ce:deflate;deflate;gzip;deflate' => 'served deflate + gzip + gzip, separate content-encoding header'],
    [ UNCOMMON_VALID, 'ce:deflate,gzip,deflate;deflate;gzip;deflate' => 'served deflate + gzip + deflate, single content-encoding header'],
    [ UNCOMMON_VALID, 'ce:deflate,gzip;ce:deflate;deflate;gzip;deflate' => 'served deflate + gzip + deflate, two content-encoding headers'],

    [ 'INVALID: specified double encodings, but content not or only once encoded or in the wrong order' ],
    [  INVALID, 'ce:gzip;ce:gzip;gzip' => 'double content-encoding header gzip, but served with single gzip'],
    [  INVALID, 'ce:gzip;ce:gzip' => 'double content-encoding header gzip, but served without encoding'],
    [  INVALID, 'ce:deflate;ce:deflate;deflate' => 'double content-encoding header deflate, but served with single deflate'],
    [  INVALID, 'ce:deflate;ce:deflate' => 'double content-encoding header deflate, but server without encoding'],

    [  INVALID, 'ce:gzip;ce:deflate;deflate;gzip' => 'content-encoding header for gzip and deflate, compressed in opposite order'],
    [  INVALID, 'ce:gzip;ce:deflate;deflate' => 'content-encoding header for gzip and deflate, but served only with single deflate'],
    [  INVALID, 'ce:gzip;ce:deflate;gzip' => 'content-encoding header for gzip and deflate, but server only with single gzip'],
    [  INVALID, 'ce:gzip;ce:deflate' => 'content-encoding header for gzip and deflate, server without encoding'],
    [  INVALID, 'ce:gzip,deflate;deflate;gzip' => 'single content-encoding header for "gzip,deflate", compressed in opposite order'],
    [  INVALID, 'ce:gzip,deflate;deflate' => 'single content-encoding header for "gzip,deflate", but served with single deflate'],
    [  INVALID, 'ce:gzip,deflate;gzip' => 'single content-encoding header for "gzip,deflate", but served with single gzip'],
    [  INVALID, 'ce:gzip,deflate' => 'single content-encoding header for "gzip,deflate", but served without encoding'],

    [  INVALID, 'ce:deflate;ce:gzip;gzip;deflate' => 'content-encoding header for deflate and gzip, compressed in opposite order'],
    [  INVALID, 'ce:deflate;ce:gzip;gzip' => 'content-encoding header for deflate and gzip, but served only with single gzip'],
    [  INVALID, 'ce:deflate;ce:gzip;deflate' => 'content-encoding header for deflate and gzip, but server only with single deflate'],
    [  INVALID, 'ce:deflate;ce:gzip' => 'content-encoding header for deflate and gzip, server without encoding'],
    [  INVALID, 'ce:deflate,gzip;gzip;deflate' => 'single content-encoding header for "deflate,gzip", compressed in opposite order'],
    [  INVALID, 'ce:deflate,gzip;gzip' => 'single content-encoding header for "deflate,gzip", but served with single gzip'],
    [  INVALID, 'ce:deflate,gzip;deflate' => 'single content-encoding header for "deflate,gzip", but served with single deflate'],
    [  INVALID, 'ce:deflate,gzip' => 'single content-encoding header for "deflate,gzip", but served without encoding'],

    # and the bad ones
    [ 'INVALID: incorrect compressed response, should not succeed' ],
    [ INVALID, 'ce:x-deflate;deflate' => 'content-encoding x-deflate, served with deflate'],
    [ INVALID, 'ce:x-deflate;deflate-raw' => 'content-encoding x-deflate, served with RFC1950 style deflate'],
    [ INVALID, 'ce:gzipx;gzip' => 'content-encoding "gzipx", served with gzip' ],
    [ INVALID, 'ce:xgzip;gzip' => 'content-encoding "xgzip", served with gzip' ],
    [ INVALID, 'ce:gzip_x;gzip' => 'content-encoding "gzip x", served with gzip' ],
    [ INVALID, 'ce:x_gzip;gzip' => 'content-encoding "x gzip", served with gzip' ],
    [ INVALID, 'ce:deflate;gzip' => 'content-encoding deflate but served with gzip'],
    [ INVALID, 'ce:gzip;deflate' => 'content-encoding gzip but served with decode'],
    [ INVALID, 'ce:gzip;gzip-split' => 'content-encoding gzip, content split into 2 gzip parts concatenated'],
    [ INVALID, 'ce:deflate' => 'content-encoding "deflate", not encoded'],
    [ INVALID, 'ce:deflate,' => 'content-encoding "deflate,", not encoded'],
    [ INVALID, 'ce:deflate-nl-,' => 'content-encoding "deflate<nl> ,", not encoded'],
    [ INVALID, 'ce:deflate-nl-,-nl-' => 'content-encoding "deflate<nl> ,<nl> ", not encoded'],

    [ 'INVALID: invalid content-encodings should not be ignored' ],
    [ INVALID, 'ce:gzip_x' => 'content-encoding "gzip x", but not encoded' ],
    [ INVALID, 'ce:deflate;ce:gzip_x;deflate' => 'content-encoding deflate + "gzip x", but only deflated' ],
    [ INVALID, 'ce:gzip_x;ce:deflate;deflate' => 'content-encoding  "gzip x" + deflate, but only deflated' ],
    [ INVALID, 'ce:foo', '"content-encoding:foo" and no encoding' ],
    [ INVALID, 'ce:rfc2047-deflate', '"content-encoding:rfc2047(deflate)" and no encoding' ],
    [ INVALID, 'ce:rfc2047-deflate;deflate', '"content-encoding:rfc2047(deflate)" with encoding' ],

    [ 'VALID: transfer-encoding should be ignored for compression' ],
    [ UNCOMMON_VALID,'te:gzip' => 'transfer-encoding gzip but not compressed'],

    [ 'INVALID: "Hiding the Content-encoding header"' ],
    [ INVALID, 'ce-space-colon-deflate;deflate' => '"Content-Encoding<space>: deflate", served with deflate' ],
    [ UNCOMMON_INVALID, 'ce-space-colon-deflate' => '"Content-Encoding<space>: deflate", served not with deflate' ],
    [ INVALID, 'ce-space-colon-gzip;gzip' => '"Content-Encoding<space>: gzip", served with gzip' ],
    [ UNCOMMON_INVALID, 'ce-space-colon-gzip' => '"Content-Encoding<space>: gzip", served not with gzip' ],

    [ INVALID, 'ce-colon-colon-deflate;deflate' => '"Content-Encoding:: deflate", served with deflate' ],
    [ UNCOMMON_INVALID, 'ce-colon-colon-deflate' => '"Content-Encoding:: deflate", served not with deflate' ],
    [ INVALID, 'ce-colon-colon-gzip;gzip' => '"Content-Encoding:: gzip", served with gzip' ],
    [ UNCOMMON_INVALID, 'ce-colon-colon-gzip' => '"Content-Encoding:: gzip", served not with gzip' ],

    [ INVALID, 'cronly-deflate;deflate' => 'Content-Encoding with only <CR> as line delimiter before, served deflate' ],
    [ UNCOMMON_INVALID, 'cronly-deflate' => 'Content-Encoding with only <CR> as line delimiter before, not served deflate' ],
    [ INVALID, 'cronly-gzip;gzip' => 'Content-Encoding with only <CR> as line delimiter before, served gzip' ],
    [ UNCOMMON_INVALID, 'cronly-gzip' => 'Content-Encoding with only <CR> as line delimiter before, not served gzip' ],

    [ UNCOMMON_INVALID, 'lfonly-deflate;deflate' => 'Content-Encoding with only <LF> as line delimiter before, served deflate' ],
    [ INVALID, 'lfonly-deflate' => 'Content-Encoding with only <LF> as line delimiter before, not served deflate' ],
    [ UNCOMMON_INVALID, 'lfonly-gzip;gzip' => 'Content-Encoding with only <LF> as line delimiter before, served gzip' ],
    [ INVALID, 'lfonly-gzip' => 'Content-Encoding with only <LF> as line delimiter before, not served gzip' ],

    [ INVALID, 'ce:crdeflate;deflate' => 'Content-Encoding:<CR>deflate, served with deflate' ],
    [ INVALID, 'ce:crdeflate' => 'Content-Encoding:<CR>deflate, not served with deflate' ],
    [ INVALID, 'ce:cr-deflate;deflate' => 'Content-Encoding:<CR><space>deflate, served with deflate' ],
    [ INVALID, 'ce:cr-deflate' => 'Content-Encoding:<CR><space>deflate, not served with deflate' ],
    [ INVALID, 'ce:crgzip;gzip' => 'Content-Encoding:<CR>gzip, served with gzip' ],
    [ INVALID, 'ce:crgzip' => 'Content-Encoding:<CR>gzip, not served with gzip' ],
    [ INVALID, 'ce:cr-gzip;gzip' => 'Content-Encoding:<CR><space>gzip, served with gzip' ],
    [ INVALID, 'ce:cr-gzip' => 'Content-Encoding:<CR><space>gzip, not served with gzip' ],

    [ 'INVALID: slightly invalid gzip encodings' ],
    [ INVALID,'ce:gzip;gzip;replace:0,2=1f8c', 'wrong gzip magic header'],
    [ INVALID,'ce:gzip;gzip;replace:2,1=88', 'wrong compression method 88 instead of 08'],
    [ UNCOMMON_VALID,'ce:gzip;gzip;replace:3,1|01', 'set flag FTEXT'],
    [ INVALID,'ce:gzip;gzip;replace:3,1|02', 'set flag FHCRC without having CRC'],
    [ INVALID,'ce:gzip;gzip;replace:3,1|02;replace:10,0=0000', 'set flag FHCRC and add CRC with 0'],
    [ UNCOMMON_VALID,'ce:gzip;gzip;replace:3,1|08;replace:10,0=2000', 'set flag FNAME and add short file name'],
    [ UNCOMMON_VALID,'ce:gzip;gzip;replace:3,1|10;replace:10,0=2000', 'set flag FCOMMENT and add short comment'],
    [ INVALID,'ce:gzip;gzip;replace:3,1|20', 'set flag reserved bit 5'],
    [ INVALID,'ce:gzip;gzip;replace:3,1|40', 'set flag reserved bit 6'],
    [ INVALID,'ce:gzip;gzip;replace:3,1|80', 'set flag reserved bit 7'],
    [ INVALID,'ce:gzip;gzip;replace:-8,4^ffffffff', 'invalidate final checksum'],
    [ INVALID,'ce:gzip;gzip;replace:-4,1^ff', 'invalidate length'],
    [ INVALID,'ce:gzip;gzip;replace:-4,4=', 'remove length'],
    [ INVALID,'ce:gzip;gzip;replace:-8,8=', 'remove checksum and length'],
    [ INVALID,'ce:gzip;gzip;replace:-4,4=;clen+4', 'remove length but set content-length header to original size'],
    [ INVALID,'ce:gzip;gzip;replace:-8,8=;clen+8', 'remove checksum and length but set content-length header to original size'],
    [ INVALID,'ce:gzip;gzip;replace:-4,4=;noclen', 'remove length and close with eof without sending length'],
    [ INVALID,'ce:gzip;gzip;replace:-8,8=;noclen', 'remove checksum and and close with eof without sending length'],
);

sub make_response {
    my ($self,$page,$spec) = @_;
    return make_index_page() if $page eq '';
    my ($hdr,$data) = content($page,$spec) or die "unknown page $page";
    my $version = '1.1';
    my $clen_extend;
    for (split(';',$spec)) {
	if ( my ($field,$v) = m{^(ce|te):(.*)$}i ) {
	    my $changed;
	    $changed++ if $v =~s{(?<=cr|lf|nl)-}{ }g;
	    $changed++ if $v =~s{cr}{\r}g;
	    $changed++ if $v =~s{lf}{\n}g;
	    $changed++ if $v =~s{nl}{\r\n}g;
	    $changed++ if $v =~s{_}{ }g;
	    $v =~s{(?<!x)-}{}g;
	    $hdr .= "Connection: close\r\n" if $changed;
	    $hdr .= $field eq 'ce' ? 'Content-Encoding:':'Transfer-Encoding:';
	    $hdr .= "$v\r\n";
	} elsif ( m{^(?:(gzip)|deflate(-raw)?)(?:(\d+)p)?$} ) {
	    my $zlib = Compress::Raw::Zlib::Deflate->new(
		-WindowBits => $1 ? WANT_GZIP : $2 ? +MAX_WBITS() : -MAX_WBITS(),
		-AppendOutput => 1,
	    );
	    my $size = int(length($data)/($3||1)) || 1;
	    my $newdata = '';
	    while ($data ne '') {
		my $out = '';
		$zlib->deflate(substr($data,0,$size,''), $out);
		$zlib->flush($out,Z_FULL_FLUSH);
		$newdata .= $out;
	    }
	    $zlib->flush($newdata,Z_FINISH);
	    $data = $newdata;
	} elsif ( $_ =~m{^gzip-split(\d+)?$} ) {
	    my $size = int(length($data)/($1||2)) || 1;
	    my $newdata = '';
	    while ($data ne '') {
		my $zlib = Compress::Raw::Zlib::Deflate->new(
		    -WindowBits => WANT_GZIP,
		    -AppendOutput => 1,
		);
		my $out = '';
		$zlib->deflate(substr($data,0,$size,''), $out);
		$zlib->flush($out,Z_FINISH);
		$newdata .= $out;
	    }
	    $data = $newdata;

	} elsif (m{^(lzma[12]|xz)$}) {
	    my ($lzma,$status) = 
		$_ eq 'xz'    ? Compress::Raw::Lzma::EasyEncoder->new(AppendOutput => 1)  :
		$_ eq 'lzma1' ? Compress::Raw::Lzma::AloneEncoder->new(AppendOutput => 1) :
		Compress::Raw::Lzma::RawEncoder->new(AppendOutput =>1);
	    $status == LZMA_OK or die "failed to create LZMA object";
	    my $newdata = '';
	    $lzma->code($data,$newdata) == LZMA_OK or die "failed to lzma encode data";
	    $lzma->flush($newdata,LZMA_FINISH) == LZMA_STREAM_END or die "failed to close lzma stream";
	    $data = $newdata;

	} elsif (m{^ce-space-colon-(.*)}) {
	    $hdr .= "Content-Encoding : $1\r\n";
	} elsif (m{^ce-colon-colon-(.*)}) {
	    $hdr .= "Content-Encoding:: $1\r\n";
	} elsif ( my ($crlf,$encoding) = m{^(lf|cr)only-(.*)}) {
	    $hdr = "X-Foo: bar" if $hdr !~s{\r\n\z}{};
	    $hdr .= ($crlf eq 'lf') ? "\n":"\r";
	    $hdr .= "Content-Encoding: $encoding\r\n";
	} elsif ($_ eq 'ce:rfc2047-deflate') {
	    $hdr .= "Content-Encoding: =?UTF-8?B?ZGVmbGF0ZQo=?=\r\n";
	} elsif ( my ($off,$len,$op,$replacement) = m{replace:(-?\d+),(\d+)([=|^])(.*)}) {
	    $replacement = pack('C*',map { hex($_) } $replacement=~m{(..)}g);
	    if ($op eq '=') {
		substr($data,$off,$len,$replacement);
	    } elsif ($op eq '|') {
		die "'$_' flags are already set" if (substr($data,$off,$len) & $replacement) eq $replacement;
		substr($data,$off,$len) |= $replacement;
	    } elsif ($op eq '^') {
		substr($data,$off,$len) ^= $replacement;
	    } else {
		die "bad op=$op in '$_'"
	    }
	} elsif (m{^clen\+(\d+)$}) {
	    $clen_extend = $1
	} elsif ($_ eq 'noclen') {
	    $clen_extend = -1;
	} else {
	    die $_
	}
    }

    my $len = length($data);
    if (!$clen_extend) {
	$hdr = "Content-length: ".length($data)."\r\n".$hdr;
    } elsif ($clen_extend<0) {
	$hdr = "Connection: close\r\n$hdr";
    } else {
	$hdr = "Connection: close\r\nContent-length: ".(length($data)+$clen_extend)."\r\n".$hdr;
    }
    return "HTTP/$version 200 ok\r\n$hdr\r\n$data";
}

1;
