# Copyright (C) E-MetroTel, 2015-2018 - All Rights Reserved
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of
# a written license agreement with E-MetroTel.

%define install_dir          /var/www
%define _initrddir           /etc/init.d
%define _httpd_dir           /etc/httpd/conf.d
%define temp_dir             /tmp
%define _rsyslogd_dir        /etc/rsyslog.d
%define _logrotated_dir      /etc/logrotate.d
%define syslogconf_file      /etc/rsyslog.conf
%define _logfile_dir         /var/log/ucx
%define facility             local5
%define facility_str         %{facility}.none
%define syslog_remote_str    '"-m 0 -r"'
%define syslog_sysconfig_file /etc/sysconfig/rsyslog
%define service_check_file    %{temp_dir}/ucx_ucc_service_active
%define httpd_conf_check_file %{temp_dir}/ucx_ucc_conf
%define rsyslog_conf_chk_file %{temp_dir}/ucx_ucc_log_conf
%define iex_config_file       iex.exs
%define ucx_ucc_sbin_dir      /usr/sbin
%define safe_name             safe_ucx_ucc
%define debug_package         %{nil}

# Use the following for pre-release versions
%define release_tag           alpha1
%define version_tag           -%{release_tag}

# Use the following release and version tags for post-release versions
# define release_tag           %{nil}
# define version_tag           %{nil}

%global __prelink_undo_cmd %{nil}

Name: ucx_ucc
Version: 1.0.0

# Up issuing the release is NOT supported due to live upgrades. Please
# up issue the Version only
Release: 0%{release_tag}%{?dist}
Summary: UCx UCC Client

Group:         Applications/Communications
License:       E-MetroTel
URL:           http://www.emetrotel.com
Source0:       %{name}-%{version}%{version_tag}.tgz
BuildRoot:     %{_tmppath}/%{name}-root
BuildArchitectures: x86_64
AutoReq:  0
Provides: %{name}
BuildRequires: elixir >= 1.5.2
BuildRequires: erlang >= 20.1

%description
UCx UCC Client is a Unified Communication Client solution which includes UNISTIM browser based UCx soft phone
built on WebRTC technology and UCx Chat application with video capability.

%prep
%setup -q -n %{name}

%build
MIX_ENV=prod mix do deps.get, deps.compile
cd assets && npm install mscs && npm install
./node_modules/brunch/bin/brunch b -p
cd ..
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/tmp
mkdir -p $RPM_BUILD_ROOT/var/lib/msc
mkdir -p $RPM_BUILD_ROOT/root
mkdir -p $RPM_BUILD_ROOT/var/lib/asterisk
mkdir -p $RPM_BUILD_ROOT/etc/asterisk
mkdir -p $RPM_BUILD_ROOT%{install_dir}/%{name}
mkdir -p $RPM_BUILD_ROOT%{_initrddir}
mkdir -p $RPM_BUILD_ROOT%{ucx_ucc_sbin_dir}
tar xzf %{_topdir}/BUILD/%{name}/_build/prod/rel/%{name}/releases/%{version}%{version_tag}/%{name}.tar.gz -C %{buildroot}%{install_dir}/%{name}
cp -r $RPM_BUILD_DIR/%{name}/rpm/SOURCES/* %{buildroot}/

%clean
rm -rf $RPM_BUILD_ROOT

%pre

# work around for wrong cookie permissions
if [ -f /var/lib/asterisk/.erlang.cookie ]; then
  rm /var/lib/asterisk/.erlang.cookie
fi

if [ $1 -eq 2 ]; then  # upgrade
    # check if service is running
    /sbin/service %{name} status  > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
      /sbin/service %{name} stop   > /dev/null 2>&1
      touch %{service_check_file}
      # need to wait for service to fully shutdown
      sleep 1
    fi
    if [ ! -f %{_httpd_dir}/%{name}.conf ]; then
      touch %{httpd_conf_check_file}
    fi
    if [ ! -f %{_rsyslogd_dir}/%{name}.conf ]; then
      touch %{rsyslog_conf_chk_file}
    fi
    modload_str='$ModLoad'
    modloadparm_str='imudp'
    udp_str='$UDPServerRun'
    udpport_str='514'

    sed -i "s/\(^\s*$modload_str\s*$modloadparm_str.*$\)/#\1/" %{syslogconf_file}
    sed -i "s/\(^\s*$udp_str\s*$udpport_str.*$\)/#\1/" %{syslogconf_file}
    exists=$(grep -w -c %{facility_str} %{syslogconf_file});
    if [ $exists -eq 0 ]; then
        orig_str='*.info;'
        fac_str='%{facility_str};'
        line_str='\/var\/log\/messages'
        sed -i "/$line_str/s/$orig_str/$orig_str$fac_str/" %{syslogconf_file}
    fi
    pattern1='# ucx_ucc log'
    pattern2='\/var\/log\/ucx\/ucx_ucc.log'
    sed -i "/$pattern1/d" %{syslogconf_file}
    sed -i "/$pattern2/d" %{syslogconf_file}

    exists=$(grep -w -c %{syslog_remote_str} %{syslog_sysconfig_file})
    if [ $exists -eq 1 ]; then
      sed -i "/-m 0 -r/d" %{syslog_sysconfig_file}
    fi

fi

%post
# syslog facility configuration
log_file=%{name}.log
change_own_grp()
{
    /bin/chgrp -R asterisk $1
    /bin/chown -R asterisk $1
}

if [ $1 -eq 1 ]; then
    # new install

    # add the Softclient group and permissions
    /usr/bin/sqlite3 /var/www/db/acl.db < /var/lib/msc/acl_up.sql

    change_own_grp %{install_dir}/%{name}
    change_own_grp %{_logfile_dir}

    fac_str='%{facility_str};'
    orig_str='*.info;'
    line_str='\/var\/log\/messages'
    sed -i "/$line_str/s/$orig_str/$orig_str$fac_str/" %{syslogconf_file}

    /sbin/chkconfig --add %{name}
    /sbin/service %{name} start  > /dev/null 2>&1
    /sbin/service %{name} stop  > /dev/null 2>&1
    change_own_grp %{install_dir}/%{name}
    /sbin/service %{name} start  > /dev/null 2>&1

    /sbin/service rsyslog restart > /dev/null 2>&1
    /sbin/service httpd restart > /dev/null 2>&1
fi

if [ $1 -eq 2 ]; then
    # upgrade
    change_own_grp %{install_dir}/%{name}
    change_own_grp %{_logfile_dir}

    if [ -f %{httpd_conf_check_file} ]; then
      service httpd restart > /dev/null 2>&1
      rm -f %{httpd_conf_check_file}
    fi
    if [ -f %{rsyslog_conf_chk_file} ]; then
      service rsyslog restart > /dev/null 2>&1
      rm -f %{rsyslog_conf_chk_file}
    fi
    # start service if it was running
    if [ -f %{service_check_file} ]; then
       /sbin/service %{name} start  > /dev/null 2>&1
       rm -f %{service_check_file}
    fi
fi

exit 0

%preun

if [ "$1" = 0 ]; then
    # package remove

    # remove the Softclient group, permissions, and users
    /usr/bin/sqlite3 /var/www/db/acl.db < /var/lib/msc/acl_down.sql

    /sbin/service %{name} stop > /dev/null 2>&1
    /sbin/chkconfig --del %{name}

    fac_str='%{facility_str};'
    line_str='\/var\/log\/messages'
    sed -i "/$line_str/s/$fac_str//" %{syslogconf_file}

    /sbin/service rsyslog restart > /dev/null 2>&1
    /sbin/service httpd restart > /dev/null 2>&1
fi
exit 0

%files
%defattr(-, asterisk, asterisk, -)
%{_logrotated_dir}/%{name}.logrotate
%config(noreplace) %{_rsyslogd_dir}/%{name}.conf

%defattr(755, root, root, -)
%{ucx_ucc_sbin_dir}/%{safe_name}

%defattr(755, asterisk, asterisk, 755)
%{_initrddir}/%{name}
%{install_dir}/%{name}/*
/var/lib/msc

%changelog
* Tue Dec 12 2017 Joseph Abraham Pallen <joseph.abraham@emetrotel.com> 1.0.0-0alpha1
 - first prototype rpm build for UCx UCC client
