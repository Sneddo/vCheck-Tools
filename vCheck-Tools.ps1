Add-Type -AssemblyName presentationframework

[xml]$XAML = @"
	<Window
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Height="500" Width="500" Title="vCheck Tools">
	
		<DockPanel>
			<DockPanel DockPanel.Dock="Top">
				<Image Width="200" Source="c:\temp\vCheck\Styles\VMware\Header.jpg"/>
				<Label FontSize="16" FontWeight="Bold" Content="Tools" Background="#0A77BA" Foreground="White" Height="55" VerticalAlignment="Center" />
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
						<Label Content="Powershell Version" HorizontalAlignment="Left" Grid.Row="0" Grid.Column="0" VerticalAlignment="Top" Height="30" Width="170" Background="#0A77BA" Foreground="White"/>
						<TextBox Name="txtPowershellVer" HorizontalAlignment="Stretch" Height="30" Grid.Row="0" Grid.Column="1"  TextWrapping="Wrap" Text="" VerticalAlignment="Top" IsEnabled="False" />
						<Label Content="PowerCLI Version" HorizontalAlignment="Left" Grid.Row="2" Grid.Column="0"  VerticalAlignment="Top" Height="30" Width="170" Background="#0A77BA" Foreground="White"/>
						<TextBox Name="txtPowerCLIVer" HorizontalAlignment="Stretch" Height="30" Grid.Row="2" Grid.Column="1" TextWrapping="Wrap" Text="" VerticalAlignment="Top" IsEnabled="False" /> 
						<Label Content="vCheck Version" HorizontalAlignment="Left" Grid.Row="4" Grid.Column="0"  VerticalAlignment="Top" Height="30" Width="170" Background="#0A77BA" Foreground="White"/>
						<TextBox Name="txtvCheckVer" HorizontalAlignment="Stretch" Height="30" Grid.Row="4" Grid.Column="1"  TextWrapping="Wrap" Text="" VerticalAlignment="Top" IsEnabled="False" /> 
					</Grid>
				</TabItem>
				
				<TabItem Name="tab_vCheckConfig" Header="Configure">
					<Grid Name="grid_Config" Margin="0,0,-0.2,0.2">
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
					</Grid>
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
						<Label Content="Start Time" HorizontalAlignment="Left" Grid.Row="0" Grid.Column="0" VerticalAlignment="Top" Height="30" Width="170" Background="#0A77BA" Foreground="White"/>
						<DatePicker Name="SchDate" HorizontalAlignment="Stretch" Height="30"  Grid.Row="0" Grid.Column="1" VerticalAlignment="Top" />
						<Label Content="Recurrance" HorizontalAlignment="Left" Grid.Row="2" Grid.Column="0" VerticalAlignment="Top" MinHeight="30" Width="170" Background="#0A77BA" Foreground="White"/>
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

# Add Snapin
Add-PSSnapin  VMware.VimAutomation.Core

#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#===========================================================================
# Add events to Form Objects
#===========================================================================
$btn_Exit.Add_Click({$form.Close()})

#===========================================================================
# Populate Tabs
#===========================================================================
# Add content - Info 
$txtPowershellVer.Text = $host.Version.Tostring()
$txtPowerCLIVer.Text = (Get-PowerCLIVersion).UserFriendlyVersion -replace "VMware vSphere PowerCLI", ""
$txtvCheckVer.Text = ((Get-Content ("{0}\vCheck.ps1" -f $pwd) | Select-String -Pattern "\$+Version\s=").toString().split("=")[1]).Trim(' "')

# Add content - Plugins
. .\vCheckUtils.ps1 | Out-Null
$Plugins = Get-VCheckPlugin 
$collection = new-object System.Collections.ObjectModel.ObservableCollection[Object] #New-Object System.Collections.ArrayList
$Plugins | %{ $collection.add( ($_ | Select Status, Name, Version) ) }
$grid_Plugins.itemssource = $collection

# Add Content - Configure
$label = new-object System.Windows.Controls.Label
$label.Content = "blah"
$label.HorizontalAlignment = "Left"
$label.VerticalAlignment="Top" 
$label.Height="30" 
$label.Width="170" 
$label.Background="#0A77BA" 
$label.Foreground="White"
$grid_Config.Children.Add($label) | Out-Null


$Form.ShowDialog() | out-null
