#! c:\perl\bin;
$min = 5;
$svnlook = '"C:\csvn\bin\svnlook.exe"';

#--------------------------------------------
$repos = $ARGV[0];
$txn = $ARGV[1];
$pattern = "[\!\@\#\$\%\^\&\*\(\)\{\}\<\>\+\`\?\=\~\,\;\:\'\"]";
$msg = `$svnlook log -t "$txn" "$repos"`;

log_msg_chk();
space_chk();
#java_syntax_chk();
#sql_syntax_chk();
exit(0);

sub log_msg_chk {
chomp($msg);
if ( length($msg) == 0 )
	{
	print STDERR "A comment is mandatory \n";
	print STDERR "Specify an appropriate comment for the check-in \n";
	exit(1);
	}
elsif ( length($msg) < $min ) 
	{ 
	print STDERR "Comment length is too small \n"; 
	print STDERR "Provide a comment whch contains atleast $min characters \n";
	exit(1); 
	}
}

sub space_chk {
@sqlfiles = `$svnlook changed -t "$txn" "$repos"`;
chomp(@sqlfiles);
foreach $_(@sqlfiles) {
$_ =~ tr /\//_/;	
	if ($_ =~ /^[U|A]+\s+\w+(\s+|$pattern|\[\])/)
		{
		print STDERR "Spaces or special characters(\!\@\#\$\%\^\&\*\(\)\{\}\<\>\+\`\?\=\~\,\;\:\'\"\[\]) found in one of the files or folders which is checked in \n";
		print STDERR "Modify the folder or file name accordingly \n";
		exit(1);
		}
	}
}

sub java_syntax_chk {
@javafiles = `$svnlook changed -t "$txn" "$repos"`;
chomp(@javafiles);
foreach $_(@javafiles) 
	{
		@list = split (/\s+/);
		$file = $list[1];
		if ($file =~ /java$/i && $file !~ /test/i && $_ =~ /^[U|A]/)
			{
			@contents =`$svnlook cat -t "$txn" "$repos" "$file"`;
			chomp(@contents);
			foreach $tmp (@contents) 
				{			
				if ($tmp =~ /system.out.println/i && $tmp !~ /^\s*\/\//)
					{						
						print STDERR "$file file contains print statement which needs to be removed \n";
						print STDERR "Make the necessary changes before checking in \n";
						exit(1);																
					}				
				}
			}
		
	}
}

sub sql_syntax_chk {
$cnt = 0;
$cnt1 = 0;
@files = `$svnlook changed -t "$txn" "$repos"`;
chomp(@files);
foreach $_(@files) 
	{
		@list = split (/\s+/);
		$file = $list[1];
		if ($file =~ /sql$/i && $_ =~ /^[U|A]/)
			{
				@contents =`$svnlook cat -t "$txn" "$repos" "$file"`;
				chomp(@contents);
				foreach $tmp (@contents) 
					{			
						if ($tmp =~ /update|select|insert|alter|create/i && $tmp !~ /^(\/\*|\-\-)/)
							{
								$cnt++;
							}

						if ($tmp =~ /\;/ && $tmp !~ /^(\/\*|\-\-)/)
							{
								$cnt1++;
							}
					}
				if ($cnt != $cnt1)
					{
						print STDERR "The syntax of your script $file is not proper \n";
						print STDERR "Make the necessary changes before checking in \n";
						exit(1);
					}
			}
	}

}
