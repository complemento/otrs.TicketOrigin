# --
# --

package Kernel::System::GenericAgent::SenderArticleType;

use strict;
use warnings;
use Data::Dumper;

use Kernel::System::DynamicField;
use Kernel::System::DynamicField::Backend;

# use Kernel::System::Priority;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicFieldBackend',
    'Kernel::System::Ticket',
);


sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{DynamicFieldObject}         = $Kernel::OM->Get('Kernel::System::DynamicField');
    $Self->{LogObject}                  = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{TicketObject}               = $Kernel::OM->Get('Kernel::System::Ticket');
    $Self->{DynamicFieldBackendObject}  = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

	# Stores the actual process and activity
	my %FirstArticle = $Self->{TicketObject}->ArticleFirstArticle(
       TicketID      => $Param{TicketID},
       DynamicFields => 0,     # 0 or 1, see ArticleGet()
	);

	if (!%FirstArticle){
		return;
	}
	
	my $ArticleType = $Self->{DynamicFieldObject}->DynamicFieldGet(
   		Name => 'ArticleType',
	);
	my $Success = $Self->{DynamicFieldBackendObject}->ValueSet(
		DynamicFieldConfig	=> $ArticleType,
		ObjectID			=> $Param{TicketID}, 
		Value				=> $Kernel::OM->Get('Kernel::Language')->Translate($FirstArticle{ArticleType}),
		UserID				=> 1,
	);

	my $SenderType = $Self->{DynamicFieldObject}->DynamicFieldGet(
   		Name => 'SenderType',
	);
	$Success = $Self->{DynamicFieldBackendObject}->ValueSet(
		DynamicFieldConfig	=> $SenderType,
		ObjectID			=> $Param{TicketID}, 
		Value				=> $Kernel::OM->Get('Kernel::Language')->Translate($FirstArticle{SenderType}),
		UserID				=> 1,
	);

	my $SenderArticleType = $Self->{DynamicFieldObject}->DynamicFieldGet(
   		Name => 'SenderArticleType',
	);
	$Success = $Self->{DynamicFieldBackendObject}->ValueSet(
		DynamicFieldConfig	=> $SenderArticleType,
		ObjectID			=> $Param{TicketID}, 
		Value				=> $Kernel::OM->Get('Kernel::Language')->Translate($FirstArticle{SenderType})." - ".
                               $Kernel::OM->Get('Kernel::Language')->Translate($FirstArticle{ArticleType}),
		UserID				=> 1,
	);

    return $Success;
}

1;
