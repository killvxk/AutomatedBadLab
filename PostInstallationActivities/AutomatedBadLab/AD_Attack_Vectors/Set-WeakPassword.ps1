
Function Set-WeakPassword {

    # Ensure the misconfigured users have a weak password
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)][string[]]$VulnUsers
    )

    Write-Host "  [+] Configuring Weak Passwords for roastable Users" -ForegroundColor Green

    $BadPasswords = @('qwerty', 'password', 'abc1234', 'football', 'letmein', '69696969', 'hunter2', 'qwertyuiop', '1234321', 'mustang', '1qaz2wsx', 'qazwsxedc', '123qwe1', 'trustno1', 'asdfghj', 'batman1', 'iloveyou', 'sunshine', 'starwars', 'klaster', '11223344', 'george1', 'asshole1', 'computer', 'michelle', 'jessica', 'pepper1', '1111111', 'zxcvbn', '555555', '11111111', '131313', 'freedom', '777777', 'pass', 'fuck', 'maggie', '159753', 'aaaaaa1', 'ginger1', 'princess', 'joshua1', 'cheese1', 'amanda1', 'summer1', 'love111', 'ashley', '6969111', 'nicole', 'chelsea', 'biteme', 'matthew', 'access', 'yankees', '987654321', 'dallas', 'austin', 'thunder', 'taylor', 'matrix', 'william', 'corvette', 'hello', 'martin', 'heather', 'secret', 'fucker', 'merlin', 'diamond', '1234qwer', 'gfhjkm', 'hammer', 'silver', '222222', '88888888', 'anthony', 'justin', 'test', 'bailey', 'q1w2e3r4t5', 'patrick', 'internet', 'scooter', 'orange', '11111', 'golfer', 'cookie', 'richard', 'samantha', 'bigdog', 'guitar', 'jackson', 'whatever', 'mickey', 'chicken', 'sparky', 'snoopy', 'maverick', 'phoenix', 'camaro', 'sexy', 'peanut', 'morgan', 'welcome', 'falcon', 'cowboy', 'ferrari', 'samsung', 'andrea', 'smokey', 'steelers', 'joseph', 'mercedes', 'dakota', 'arsenal', 'eagles', 'melissa', 'boomer', 'booboo', 'spider', 'nascar', 'monster', 'tigers', 'yellow', 'xxxxxx', '123123123', 'gateway', 'marina', 'diablo', 'bulldog', 'qwer1234', 'compaq', 'purple', 'hardcore', 'banana', 'junior', 'hannah', '123654', 'porsche', 'lakers', 'iceman', 'money', 'cowboys', '987654', 'london', 'tennis', '999999', 'ncc1701', 'coffee', 'scooby', '0000', 'miller', 'boston', 'q1w2e3r4', 'fuckoff', 'brandon', 'yamaha', 'chester', 'mother', 'forever', 'johnny', 'edward', '333333', 'oliver', 'redsox', 'player', 'nikita', 'knight', 'fender', 'barney', 'midnight', 'please', 'brandy', 'chicago', 'badboy', 'iwantu', 'slayer', 'rangers', 'charles', 'angel', 'flower', 'bigdaddy', 'rabbit', 'wizard', 'bigdick', 'jasper', 'enter', 'rachel', 'chris', 'steven', 'winner', 'adidas', 'victoria', 'natasha', '1q2w3e4r', 'jasmine', 'winter', 'prince', 'panties', 'marine', 'ghbdtn', 'fishing', 'cocacola', 'casper', 'james', '232323', 'raiders', '888888', 'marlboro', 'gandalf', 'asdfasdf', 'crystal', '87654321', '12344321', 'sexsex', 'golden', 'blowme', 'bigtits', '8675309', 'panther', 'lauren', 'angela', 'bitch', 'spanky', 'thx1138', 'angels', 'madison', 'winston', 'shannon', 'mike', 'toyota', 'blowjob', 'jordan23', 'canada', 'sophie', 'Password', 'apples', 'dick', 'tiger', 'razz', '123abc', 'pokemon', 'qazxsw', '55555', 'qwaszx', 'muffin', 'johnson', 'murphy', 'cooper', 'jonathan', 'liverpoo', 'david', 'danielle', '159357', 'jackie', '1990', '123456a', '789456', 'turtle', 'horny', 'abcd1234', 'scorpion', 'qazwsxedc', '101010', 'butter', 'carlos', 'password1', 'dennis', 'slipknot', 'qwerty123', 'booger', 'asdf', '1991', 'black', 'startrek', '12341234', 'cameron', 'newyork', 'rainbow', 'nathan', 'john', '1992', 'rocket', 'viking', 'redskins', 'butthead', 'asdfghjkl', '1212', 'sierra', 'peaches', 'gemini', 'doctor', 'wilson', 'sandra', 'helpme', 'qwertyui', 'victor', 'florida', 'dolphin', 'pookie', 'captain', 'tucker', 'blue', 'liverpool', 'theman', 'bandit', 'dolphins', 'maddog', 'packers', 'jaguar', 'lovers', 'nicholas', 'united', 'tiffany', 'maxwell', 'zzzzzz', 'nirvana', 'jeremy', 'suckit', 'stupid', 'porn', 'monica', 'elephant', 'giants', 'jackass', 'hotdog', 'rosebud', 'success', 'debbie', 'mountain', '444444', 'xxxxxxxx', 'warrior', '1q2w3e4r5t', 'q1w2e3', '123456q', 'albert', 'metallic', 'lucky', 'azerty', '7777', 'shithead', 'alex', 'bond007', 'alexis', '1111111', 'samson', '5150', 'willie', 'scorpio', 'bonnie', 'gators', 'benjamin', 'voodoo', 'driver', 'dexter', '2112', 'jason', 'calvin', 'freddy', '212121', 'creative', '12345a', 'sydney', 'rush2112', '1989', 'asdfghjk', 'red123', 'bubba', '4815162342', 'passw0rd', 'trouble', 'gunner', 'happy', 'fucking', 'gordon', 'legend', 'jessie', 'stella', 'qwert', 'eminem', 'arthur', 'apple', 'nissan', 'bullshit', 'bear', 'america', '1qazxsw2', 'nothing', 'parker', '4444', 'rebecca', 'qweqwe', 'garfield', '01012011', 'beavis', '69696969', 'jack', 'asdasd', 'december', '2222', '102030', '252525', '11223344', 'magic', 'apollo', 'skippy', '315475', 'girls', 'kitten', 'golf', 'copper', 'braves', 'shelby', 'godzilla', 'beaver', 'fred', 'tomcat', 'august', 'buddy', 'airborne', '1993', '1988', 'lifehack', 'qqqqqq', 'brooklyn', 'animal', 'platinum', 'phantom', 'online', 'xavier', 'darkness', 'blink182', 'power', 'fish', 'green', '789456123', 'voyager');
	
    # For each user, set a weak password
    foreach ($User in $VulnUsers) {
        $RandomPassword = Get-Random $BadPasswords
        Write-Verbose "Setting $RandomPassword as password for $User"
        Get-ADUser $User | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString $RandomPassword -AsPlainText -Force)
    }

    # Pass back the vulnerable users to the main script
    return $VulnUsers
}
