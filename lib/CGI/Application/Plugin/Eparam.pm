package CGI::Application::Plugin::Eparam;

#=====================================================================
# 日本語環境でparamの値を事前に変換する
#---------------------------------------------------------------------
# 作成    : 2005/06/22 aska
#---------------------------------------------------------------------
# $Id: Eparam.pm 17 2005-07-01 08:39:11Z aska $
#=====================================================================
use 5.004;
use strict;
use Carp;

sub import {
	my $class = shift;
	my $caller = caller;
	
	$CGI::Application::Plugin::Eparam::debug = undef;
	$CGI::Application::Plugin::Eparam::econv = undef;
	$CGI::Application::Plugin::Eparam::icode = undef;
	$CGI::Application::Plugin::Eparam::ocode = undef;

	$CGI::Application::Plugin::Eparam::temp_econv = undef;
	$CGI::Application::Plugin::Eparam::temp_icode = undef;
	$CGI::Application::Plugin::Eparam::temp_ocode = undef;
	
	no strict 'refs';
	*{$caller.'::eparam'} = \&eparam;
	
}

#=====================================================================
# 変換後のparamを返す
#---------------------------------------------------------------------
# 引数    :key名
# 戻り値  :文字コード変換後のvalue値
# 使用例  :my $val = $self->eparam('key');
#=====================================================================
sub eparam {
	my $self = shift;
	
	#-----------------------------
	# 変換ロジックの実装
	#-----------------------------
	unless ( $CGI::Application::Plugin::Eparam::econv ) {
		if ( $Encode::VERSION ) {                              # Encode.pm
			$CGI::Application::Plugin::Eparam::econv = 
				sub { Encode::from_to(${$_[0]},$_[2],$_[1] );};
		} elsif ( $Jcode::VERSION ) {                          # Jcode.pm
			$CGI::Application::Plugin::Eparam::econv = 
				sub { Jcode::convert( $_[0], $_[1], $_[2] ); };
		} else {
			croak "You must be use Encode or use Jcode or set econv.";
		}
	}
	
	my $debug = $CGI::Application::Plugin::Eparam::debug;
	
	my $icode = $CGI::Application::Plugin::Eparam::temp_icode || $CGI::Application::Plugin::Eparam::icode;
	my $ocode = $CGI::Application::Plugin::Eparam::temp_ocode || $CGI::Application::Plugin::Eparam::ocode;
	my $econv = $CGI::Application::Plugin::Eparam::temp_ecode || $CGI::Application::Plugin::Eparam::econv;
	
	carp "icode:".$icode if $debug;
	carp "ocode:".$ocode if $debug;
	carp "econv:".$econv if $debug;
	
	if ( !wantarray ) {
		my $val = $self->query->param(@_);
		$econv->(\$val, $ocode, $icode) if defined $val && $icode ne $ocode;
		carp "value:".$val if $debug;
		return $val;
	} else {
		my @val = $self->query->param(@_);
		map { $econv->(\$_, $ocode, $icode) } @val if scalar(@val) && $icode ne $ocode;
		carp "value:".join(',', @val) if $debug;
		return @val;
	}
}

1;