<#
.SYNOPSIS 
	This script aims to make configuring an scheduling vCheck easier by 
	providing a graphical interface.
.DESCRIPTION
	The following options can be configured for vCheck:
		- Plugins
		- Settings
		- Scheduled Task
		
	Possible other options:
		- Config Backup/Restore (for vCheck and Plugins)
		- Updates (Plugin and vCheck Core)
		- ???
.NOTES 
   File Name  : vCheck-Tools.ps1 
   Author     : John Sneddon - @JohnSneddonAU
   Version    : 0.1
  
.INPUTS
   No inputs required
.OUTPUTS
   No outputs
#>
################################################################################
#                                INITIALISATION                                #
################################################################################
# Initialise any required variables
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)

################################################################################
#                                 REQUIREMENTS                                 #
################################################################################
# Load all requirements for the script here
# Adding PowerCLI core snapin
if (!(Get-PSSnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
	Add-PSSnapin VMware.VimAutomation.Core
}

# Include vCheckUtils (for now - merge this eventually
 . .\vCheckUtils.ps1 | Out-Null
 
# Add WPF Type
Add-Type -AssemblyName PresentationFramework

################################################################################
#                                   LANGUAGE                                   #
################################################################################
$l = DATA {
    ConvertFrom-StringData @'
		XAMLError = Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered.
'@ }
# If a localized version is available, overwrite the defaults
Import-LocalizedData -BaseDirectory ($ScriptPath + "\lang") -bindingVariable l -ErrorAction SilentlyContinue

################################################################################
#                                     GUI                                      #
################################################################################
# Use XAML to define the form, data to be populated in code
[xml]$XAML = @"
	<Window
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Height="500" Width="500" Title="vCheck Tools">
		<Window.Resources>
			<Style TargetType="Label">
				<Setter Property="Height" Value="30" />			
				<Setter Property="Background" Value="#0A77BA" />
				<Setter Property="Foreground" Value="White" />
				<Setter Property="VerticalAlignment" Value="Top" />
				<Setter Property="HorizontalAlignment" Value="Left" />
			</Style>
			<BitmapImage x:Key="masterImage" UriSource="{PATH}\Styles\VMware\Header.jpg" />
			<CroppedBitmap x:Key="croppedImage" Source="{StaticResource masterImage}" SourceRect="0 0 246 108"/>
		</Window.Resources>
		<DockPanel>
			<DockPanel DockPanel.Dock="Top" Background="#0A77BA" >
				<Image Source="{StaticResource croppedImage}" Width="123" Height="54"/>
				<Label FontSize="18" FontWeight="Bold" Padding="0 17 0 17" Content="vCheck Tools" Height="54" VerticalAlignment="Center"/>
				<Label FontSize="10"  Content="by John Sneddon - @JohnSneddonAU" Padding="0 10 0 0" VerticalAlignment="Bottom" HorizontalAlignment="Right" />
			</DockPanel>
			
			<DockPanel DockPanel.Dock="Bottom" Margin="5">
				<Button Name="btn_Exit" Content="Exit" Height="34" BorderThickness="0"/>
			</DockPanel>
			
			<TabControl TabStripPlacement="Top" Margin="0">
				<TabItem Name="tab_vCheckInfo" Header="Information">
					<Grid Margin="0,0,-0.2,0.2">
					<Grid.ColumnDefinitions>  
						<ColumnDefinition Width="175"/>  
						<ColumnDefinition />  
					</Grid.ColumnDefinitions>  
					<Grid.RowDefinitions>  
						<RowDefinition Height="30" />  
						<RowDefinition Height="5" />
						<RowDefinition Height="30" />  
						<RowDefinition Height="5" />
						<RowDefinition Height="30" />  
					</Grid.RowDefinitions>  
						<Label Content="Powershell Version" Width="170" Grid.Row="0" Grid.Column="0" />
						<TextBox Name="txtPowershellVer" HorizontalAlignment="Stretch" Height="30" Grid.Row="0" Grid.Column="1"  TextWrapping="Wrap" Text="" VerticalAlignment="Top" IsEnabled="False" />
						<Label Content="PowerCLI Version" Width="170" Grid.Row="2" Grid.Column="0" />
						<TextBox Name="txtPowerCLIVer" HorizontalAlignment="Stretch" Height="30" Grid.Row="2" Grid.Column="1" TextWrapping="Wrap" Text="" VerticalAlignment="Top" IsEnabled="False" /> 
						<Label Content="vCheck Version" Width="170" Grid.Row="4" Grid.Column="0" />
						<TextBox Name="txtvCheckVer" HorizontalAlignment="Stretch" Height="30" Grid.Row="4" Grid.Column="1"  TextWrapping="Wrap" Text="" VerticalAlignment="Top" IsEnabled="False" /> 
					</Grid>
				</TabItem>
				
				<TabItem Name="tab_vCheckConfig" Header="Configure">
					<DockPanel>
						<ScrollViewer>
							<Grid Name="grid_Config" Margin="0,0,-0.2,0.2">
								<Grid.ColumnDefinitions>  
									<ColumnDefinition Width="175"/>  
									<ColumnDefinition />  
								</Grid.ColumnDefinitions> 
							</Grid>
						</ScrollViewer>
					</DockPanel>

				</TabItem>
				
				<TabItem Name="tab_vCheckPugins" Header="Plugins">
					<DataGrid Name="grid_Plugins" AutoGenerateColumns="true"/>
				</TabItem>

				<TabItem Name="tab_vCheckTask" Header="Schedule vCheck">
					<Grid Margin="0,0,-0.2,0.2">
						<Grid.ColumnDefinitions>  
							<ColumnDefinition Width="175"/>  
							<ColumnDefinition />  
						</Grid.ColumnDefinitions>  
						<Grid.RowDefinitions>  
							<RowDefinition Height="30" />  
							<RowDefinition Height="5" />
							<RowDefinition MinHeight="30" />  
							<RowDefinition Height="5" />
							<RowDefinition Height="30" />  
						</Grid.RowDefinitions>
						<Label Content="Start Time" Width="170" Grid.Row="0" Grid.Column="0" />
						<DatePicker Name="SchDate" HorizontalAlignment="Stretch" Height="30"  Grid.Row="0" Grid.Column="1" VerticalAlignment="Top" />
						<Label Content="Recurrance" Width="170" Grid.Row="2" Grid.Column="0" />
						<StackPanel Grid.Row="2" Grid.Column="1" HorizontalAlignment="Stretch">
							<RadioButton GroupName="recurrance" Content="None" IsChecked="True"/>
							<RadioButton GroupName="recurrance" Content="Daily" />
							<RadioButton GroupName="recurrance" Content="Weekly" />
							<RadioButton GroupName="recurrance" Content="Monthly 7" />
						</StackPanel>
					</Grid>
				</TabItem>
			</TabControl>
		</DockPanel>
	</Window>
"@

$xaml.Window.'Window.Resources'.BitmapImage.UriSource = $xaml.Window.'Window.Resources'.BitmapImage.UriSource -replace "{PATH}", $ScriptPath

#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
Try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
Catch{Write-Error $l.XAMLError; exit}

# Read form controls into Powershell Objects for ease of maodifcation
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

################################################################################
#                                    EVENTS                                    #
################################################################################
# Exit Button Clicked
$btn_Exit.Add_Click({$form.Close()})


################################################################################
#                                POPULATE FORM                                 #
################################################################################
#------------------------------------ INFO ------------------------------------#
$txtPowershellVer.Text = $host.Version.Tostring()
$txtPowerCLIVer.Text = (Get-PowerCLIVersion).UserFriendlyVersion -replace "VMware vSphere PowerCLI", ""
$txtvCheckVer.Text = ((Get-Content ("{0}\vCheck.ps1" -f $pwd) | Select-String -Pattern "\$+Version\s=").toString().split("=")[1]).Trim(' "')

#----------------------------------- PLUGINS ----------------------------------#
$Plugins = Get-VCheckPlugin 
$collection = new-object System.Collections.ObjectModel.ObservableCollection[Object]
$Plugins | %{ $collection.add( ($_ | Select Status, Name, Version) ) }
$grid_Plugins.itemssource = $collection

#----------------------------------- CONFIG -----------------------------------#
$row = 0

$RowDef = new-object System.Windows.Controls.RowDefinition
$RowDef.Height = "30"
$grid_Config.RowDefinitions.Add($RowDef)
$RowDef = new-object System.Windows.Controls.RowDefinition
$RowDef.Height = "5"
$grid_Config.RowDefinitions.Add($RowDef)
$label = New-Object System.Windows.Controls.Label
$label.Content = "GlobalVariables"
$label.Background="#1D6325"
$label.HorizontalAlignment="Stretch"
$label.HorizontalContentAlignment="Stretch"
$grid_Config.Children.Add($label) | Out-Null
[Windows.Controls.Grid]::SetRow($label,$row)
[Windows.Controls.Grid]::SetColumn($label,0)
[Windows.Controls.Grid]::SetColumnSpan($label,2)
		
$file = Get-Content "GlobalVariables.ps1"
$OriginalLine = ($file | Select-String -Pattern "# Start of Settings").LineNumber
$EndLine = ($file | Select-String -Pattern "# End of Settings").LineNumber
$row=$row+2
if (!(($OriginalLine +1) -eq $EndLine)) {
	$Array = @()
	$Line = $OriginalLine

	do {
		$Question = $file[$Line]
		Write-Debug ("Line {0}: {1}" -f $Line, $Question)
		$Line ++
		$Split= ($file[$Line]).Split("=")
		$Var = ($Split[0] -replace "\$", "").Trim()
		$CurSet = $Split[1].Replace('"', '').Trim()
		
		$RowDef = new-object System.Windows.Controls.RowDefinition
		$RowDef.Height = "30"
		$grid_Config.RowDefinitions.Add($RowDef)
		
		Write-Debug ("   Row {0}: {1}={2}" -f $row, $Var, $CurSet)
		$label = new-object System.Windows.Controls.Label
		$label.Content = $Var
		$label.Width="170"
		$grid_Config.Children.Add($label) | Out-Null
		[Windows.Controls.Grid]::SetRow($label,$row)
		[Windows.Controls.Grid]::SetColumn($label,0)

		$TextBox = new-object System.Windows.Controls.TextBox
		$TextBox.Name = "txt"+$Var
		$TextBox.Text = $CurSet
		$TextBox.HorizontalAlignment = "Stretch"
		$TextBox.VerticalAlignment="Top" 
		$TextBox.Height="30" 
		[Windows.Controls.Grid]::SetRow($TextBox,$row)
		[Windows.Controls.Grid]::SetColumn($TextBox,1)
		$grid_Config.Children.Add($TextBox) | Out-Null
		
		$RowDef = new-object System.Windows.Controls.RowDefinition
		$RowDef.Height = "5"
		$grid_Config.RowDefinitions.Add($RowDef)
		
		$Line++
		$row=$row+2
		
	} Until ( $Line -ge ($EndLine -1) )
}
#---------------------------------- SCHEDULE ----------------------------------#



################################################################################
#                                    DISPLAY                                   #
################################################################################
$Form.ShowDialog() | out-null
