Describe "Basic Send-MailMessage tests" -Tags CI {
    function read-mail
    {
        Param(
            [parameter(Mandatory=$true)]
            [String]
            $mailBox
        )

        $state = "init"
        $mail = Get-Content $mailBox
        $rv = @{}
        foreach ($line in $mail)
        {
            switch ($state)
            {
                "init"
                {
                    if ($line.Length -gt 0)
                    {
                        $state = "headers"
                    }
                }
                "headers"
                {
                    if ($line.StartsWith("From: "))
                    {
                        $rv.From = $line.Substring(6)
                    }
                    elseif ($line.StartsWith("To: "))
                    {
                        if ($rv.To -eq $null)
                        {
                            $rv.To = @()
                        }

                        $rv.To += $line.Substring(4)
                    }
                    elseif ($line.StartsWith("Subject: "))
                    {
                        $rv.Subject = $line.Substring(9);
                    }
                    elseif ($line.Length -eq 0)
                    {
                        $state = "body"
                    }
                }
                "body"
                {
                    if ($line.Length -eq 0)
                    {
                        $state = "done"
                        continue
                    }

                    if ($rv.Body -eq $null)
                    {
                        $rv.Body = @()
                    }

                    $rv.Body += $line
                }
            }
        }

        return $rv
    }

    BeforeAll {
        $PesterArgs = @{ Name = "Can send mail message from user to self"}
        $alreadyHasMail = $true

        if (-not $IsLinux)
        {
            $PesterArgs["Skip"] = $true
            $PesterArgs["Name"] += " (skipped: not Linux)"
            return
        }

        $user = "jeff"
        $inPassword = Select-String "^${user}:" /etc/passwd -ErrorAction SilentlyContinue
        if (-not $inPassword)
        {
            $PesterArgs["Pending"] = $true
            $PesterArgs["Name"] += " (pending: user not in /etc/passwd)"
            return
        }

        $domain = "Chinstrap"
        if ($domain -ne [System.Environment]::MachineName)
        {
            $PesterArgs["Pending"] = $true
            $PesterArgs["Name"] += " (pending: machine name not '$domain')"
            return
        }
        $address = "$user@$domain"
        $mailStore = "/var/mail"
        $mailBox = Join-Path $mailStore $user
        $mailBoxFile = Get-Item $mailBox -ErrorAction SilentlyContinue
        if ($mailBoxFile -ne $null -and $mailBoxFile.Length -gt 2)
        {
            $PesterArgs["Pending"] = $true
            $PesterArgs["Name"] += " (pending: mailbox not empty)"
            return
        }
        $alreadyHasMail = $false
        Set-Content -Value "" -Path $mailBox -Force -ErrorAction SilentlyContinue
        $mailBoxFile = Get-Item $mailBox -ErrorAction SilentlyContinue
        if ($mailBoxFile -eq $null -or $mailBoxFile.Length -gt 2)
        {
            $PesterArgs["Pending"] = $true
            $PesterArgs["Name"] += " (pending: did not clear or create mailbox)"
            return
        }
    }
    AfterAll {
       if (-not $alreadyHasMail)
       {
           Set-Content -Value "" -Path $mailBox -Force -ErrorAction SilentlyContinue
       }
    }

    It @PesterArgs {
        $body = "Greetings from me."
        $subject = "Test message"
        Send-MailMessage -To $address -From $address -Subject $subject -Body $body -SmtpServer 127.0.0.1
        Test-Path -Path $mailBox | Should Be $true
        $mail = read-mail $mailBox
        $mail.From | Should BeExactly $address
        $mail.To.Count | Should BeExactly 1
        $mail.To[0] | Should BeExactly $address
        $mail.Body.Count | Should BeExactly 1
        $mail.Body[0] | Should BeExactly $body
    }
}
