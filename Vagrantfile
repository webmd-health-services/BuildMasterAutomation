# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vm.define 'buildmaster' do |buildmaster|
    # https://app.vagrantup.com/gusztavvargadr/boxes/sql-server
    buildmaster.vm.box = 'gusztavvargadr/sql-server'

    buildmaster.vm.network 'forwarded_port', guest: 8622, host: 8622

    buildmaster.vm.provider 'virtualbox' do |vb|
      vb.gui = true
      vb.memory = '4096'
    end

    buildmaster.vm.provider 'hyperv' do |hv|
      hv.memory = '4096'
    end

    buildmaster.vm.provision 'shell', inline: <<-'SHELL'
      $ErrorActionPreference = 'Stop'

      # InedoHub installs BuildMaster to run as the Network Service built-in.
      sqlcmd.exe -Q 'CREATE LOGIN [NT AUTHORITY\NETWORK SERVICE] FROM WINDOWS;'

      New-NetFirewallRule -DisplayName 'Allow BuildMaster Web Server' -Direction Inbound -Protocol TCP -LocalPort 8622 | Write-Verbose

      $inedoHubRoot = 'C:\Users\vagrant\Downloads\InedoHub'
      $inedoHubZip = "$($inedoHubRoot).zip"
      Invoke-WebRequest -Uri 'https://proget.inedo.com/upack/Products/download/InedoReleases/DesktopHub?contentOnly=zip&latest' -OutFile $inedoHubZip
      Expand-Archive -Path $inedoHubZip -DestinationPath $inedoHubRoot

      Install-Module -Name 'PackageManagement' -Scope CurrentUser -MinimumVersion '1.3.2' -MaximumVersion '1.4.8.1' -Repository 'PSGallery' -AllowClobber -Force
      Install-Module -Name 'PowerShellGet' -Scope CurrentUser -MinimumVersion '2.0.0' -MaximumVersion '2.2.5' -Repository 'PSGallery' -AllowClobber -Force
      Install-Module -Name 'Prism' -Scope CurrentUser -Repository 'PSGallery' -Force
      SHELL
  end
end