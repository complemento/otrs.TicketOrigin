# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::TicketOrigin;

use strict;
use warnings;

use Kernel::Output::Template::Provider;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::Log',
    'Kernel::System::State',
    'Kernel::System::Stats',
    'Kernel::System::SysConfig',
    'Kernel::System::Type',
    'Kernel::System::Valid',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}


sub CodeInstall {
    my ( $Self, %Param ) = @_;

    $Self->_CreateDynamicFields();
	$Self->_UpdateConfig();
    $Self->_ExampleGenericAgents();
    
    return 1;
}

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    $Self->_CreateDynamicFields();
	$Self->_UpdateConfig();
	
    return 1;
}

sub _ExampleGenericAgents {
    my ( $Self, %Param ) = @_;
    # Create Example Generic Agents
    my %Job = $Kernel::OM->Get('Kernel::System::GenericAgent')->JobGet(Name=>'TicketOrigin - 0 - Mark New Tickets');

    if(exists $Job{Name}){
        return 1;
    }    
	
	$Kernel::OM->Get('Kernel::System::GenericAgent')->JobAdd(
       Name => 'TicketOrigin - 0 - Mark New Tickets',
       Data => {
            EventValues => [
                'TicketCreate'
            ],
            DynamicField_SenderArticleType => '-',
            Valid => 1,
       },
       UserID => 1,
    );
    $Kernel::OM->Get('Kernel::System::GenericAgent')->JobAdd(
       Name => 'TicketOrigin - 1 - Verify New Tickets',
       Data => {

           ScheduleDays => ['6','5','4','3','2','1','0'],
           ScheduleMinutes => [
              '58','38','48','28','18','8'
            ],
            ScheduleHours => [
              '23','22','21','20','19','18','17','16','15','14','13','12','11','10','9','8','7','6','5','4','3','2','1','0'
            ],

           Search_DynamicField_SenderArticleType => '-',
           
           NewModule => 'Kernel::System::GenericAgent::SenderArticleType',
           Valid => 1,
           
       },
       UserID => 1,
    );


    return 1;
}

sub _UpdateConfig {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');


#    my @Configs = (
#        {
#            ConfigItem => 'CustomerFrontend::CommonParam###Action',
#            Value 	   => 'CustomerServiceCatalog'
#        },
#    );

#    CONFIGITEM:
#    for my $Config (@Configs) {
#        # set new setting,
#        my $Success = $SysConfigObject->ConfigItemUpdate(
#            Valid => 1,
#            Key   => $Config->{ConfigItem},
#            Value => $Config->{Value},
#        );

#    }

    return 1;
}

sub _CreateDynamicFields {
    my ( $Self, %Param ) = @_;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    # get the list of order numbers (is already sorted).
    my @DynamicfieldOrderList;
    for my $Dynamicfield ( @{$DynamicFieldList} ) {
        push @DynamicfieldOrderList, $Dynamicfield->{FieldOrder};
    }

    # get the last element from the order list and add 1
    my $NextOrderNumber = 1;
    if (@DynamicfieldOrderList) {
        $NextOrderNumber = $DynamicfieldOrderList[-1] + 1;
    }

    # get the definition for all dynamic fields for ITSM
    my @DynamicFields = $Self->_GetITSMDynamicFieldsDefinition();

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;
    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {
        next DYNAMICFIELD if ref $DynamicField ne 'HASH';
        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # create or update dynamic fields
    DYNAMICFIELD:
    for my $DynamicField (@DynamicFields) {

        my $CreateDynamicField;

        if ( ref $DynamicFieldLookup{ $DynamicField->{Name} } eq 'HASH' ) {
            # Deletes DF
            my $DynamicFieldID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
                                       Name => $DynamicField->{Name},
                                    );
            if ($DynamicFieldID->{ID}){
                  my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldDelete(
                   ID      => $DynamicFieldID->{ID},
                   UserID  => 1,
                   Reorder => 1,               # or 0, to trigger reorder function, default 1
               );
            }
        }

        # check if new field has to be created
#        if ($CreateDynamicField) {


            # create a new field
            my $FieldID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldAdd(
                InternalField => 1,
                Name          => $DynamicField->{Name},
                Label         => $DynamicField->{Label},
                FieldOrder    => $NextOrderNumber,
                FieldType     => $DynamicField->{FieldType},
                ObjectType    => $DynamicField->{ObjectType},
                Config        => $DynamicField->{Config},
                ValidID       => $ValidID,
                UserID        => 1,
            );
            next DYNAMICFIELD if !$FieldID;

            # increase the order number
            $NextOrderNumber++;
#        }
    }

    return 1;
}


sub _GetITSMDynamicFieldsDefinition {
    my ( $Self, %Param ) = @_;

    # define all dynamic fields for ITSM
    my @DynamicFields = (
        {
            Name       => 'SenderArticleType',
            Label      => 'Ticket Origin',
            FieldType  => 'Dropdown',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue   => '',
                PossibleValues =>{'-'=>'-'},
            },
        },
        {
            Name       => 'SenderType',
            Label      => 'Sender Type',
            FieldType  => 'Dropdown',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue   => '',
                PossibleValues =>{'-'=>'-'},
            },
        },
        {
            Name       => 'ArticleType',
            Label      => 'Article Type',
            FieldType  => 'Dropdown',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue   => '',
                PossibleValues =>{'-'=>'-'},
            },
        },
    );

    return @DynamicFields;
}


