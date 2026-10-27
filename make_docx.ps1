# make_docx.ps1 - Generates 100% valid, strict OpenXML DOCX without backslashes
$ErrorActionPreference = "Stop"

$workspace = "C:\xampp\htdocs\netusage-monitoring"
$outputDocx = "$workspace\NETWORK_USAGE_MONITORING_SYSTEM_DOCUMENTATION.docx"
$publicDocx = "$workspace\public\NETWORK_USAGE_MONITORING_SYSTEM_DOCUMENTATION.docx"
$tempDir = "$workspace\temp_docx_build"

if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
if (Test-Path $outputDocx) { Remove-Item -Force $outputDocx }
if (Test-Path $publicDocx) { Remove-Item -Force $publicDocx }

New-Item -ItemType Directory -Path "$tempDir\_rels" | Out-Null
New-Item -ItemType Directory -Path "$tempDir\word\_rels" | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. [Content_Types].xml
$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@
[System.IO.File]::WriteAllText("$tempDir\[Content_Types].xml", $contentTypes, $utf8NoBom)

# 2. _rels/.rels
$rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$tempDir\_rels\.rels", $rels, $utf8NoBom)

# 3. word/_rels/document.xml.rels
$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$tempDir\word\_rels\document.xml.rels", $docRels, $utf8NoBom)

# 4. word/styles.xml
$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
        <w:lang w:val="en-US"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:line="360" w:lineRule="auto" w:after="160"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>
'@
[System.IO.File]::WriteAllText("$tempDir\word\styles.xml", $styles, $utf8NoBom)

# 5. Build word/document.xml
$sb = New-Object System.Text.StringBuilder

[void]$sb.Append(@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
'@)

function Escape-Xml([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    return [System.Security.SecurityElement]::Escape($text)
}

function Add-P([string]$text, [string]$align = "both", [bool]$bold = $false, [int]$size = 24, [string]$font = "Times New Roman", [int]$spaceBefore = 0, [int]$spaceAfter = 160) {
    $esc = Escape-Xml $text
    $bTag = if ($bold) { "<w:b/>" } else { "" }
    $p = "<w:p><w:pPr><w:jc w:val=`"$align`"/><w:spacing w:before=`"$spaceBefore`" w:after=`"$spaceAfter`" w:line=`"360`" w:lineRule=`"auto`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"$font`" w:hAnsi=`"$font`"/><w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/>$bTag</w:rPr><w:t xml:space=`"preserve`">$esc</w:t></w:r></w:p>"
    [void]$sb.Append($p)
}

function Add-PageBreak {
    [void]$sb.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
}

function Add-Heading1([string]$text) {
    Add-P -text $text -align "center" -bold $true -size 32 -font "Arial" -spaceBefore 360 -spaceAfter 200
}

function Add-Heading2([string]$text) {
    Add-P -text $text -align "left" -bold $true -size 28 -font "Arial" -spaceBefore 280 -spaceAfter 140
}

function Add-Heading3([string]$text) {
    Add-P -text $text -align "left" -bold $true -size 24 -font "Arial" -spaceBefore 200 -spaceAfter 100
}

function Add-Caption([string]$text) {
    Add-P -text $text -align "center" -bold $true -size 20 -font "Arial" -spaceBefore 80 -spaceAfter 200
}

function Add-Code([string]$code) {
    $lines = $code -split "`r?`n"
    foreach ($l in $lines) {
        $esc = Escape-Xml $l
        $p = "<w:p><w:pPr><w:pBdr><w:left w:val=`"single`" w:sz=`"12`" w:space=`"4`" w:color=`"0D6EFD`"/></w:pBdr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F4F6F8`"/><w:spacing w:before=`"0`" w:after=`"40`" w:line=`"240`" w:lineRule=`"auto`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Consolas`" w:hAnsi=`"Consolas`"/><w:sz w:val=`"19`"/><w:szCs w:val=`"19`"/></w:rPr><w:t xml:space=`"preserve`">$esc</w:t></w:r></w:p>"
        [void]$sb.Append($p)
    }
}

function Add-TableRows($headers, $rows) {
    [void]$sb.Append('<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:top w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:left w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:right w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/></w:tblBorders></w:tblPr>')
    
    # Header Row
    [void]$sb.Append('<w:tr><w:trPr><w:tblHeader/></w:trPr>')
    foreach ($h in $headers) {
        $eh = Escape-Xml $h
        [void]$sb.Append("<w:tc><w:tcPr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"E8EFF8`"/></w:tcPr><w:p><w:pPr><w:jc w:val=`"left`"/><w:spacing w:before=`"80`" w:after=`"80`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:b/><w:sz w:val=`"21`"/></w:rPr><w:t>$eh</w:t></w:r></w:p></w:tc>")
    }
    [void]$sb.Append('</w:tr>')

    # Data Rows
    foreach ($row in $rows) {
        [void]$sb.Append('<w:tr>')
        foreach ($cell in $row) {
            $ec = Escape-Xml $cell
            [void]$sb.Append("<w:tc><w:tcPr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"FFFFFF`"/></w:tcPr><w:p><w:pPr><w:jc w:val=`"left`"/><w:spacing w:before=`"60`" w:after=`"60`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Times New Roman`" w:hAnsi=`"Times New Roman`"/><w:sz w:val=`"21`"/></w:rPr><w:t>$ec</w:t></w:r></w:p></w:tc>")
        }
        [void]$sb.Append('</w:tr>')
    }

    [void]$sb.Append('</w:tbl><w:p><w:pPr><w:spacing w:after="160"/></w:pPr></w:p>')
}

# ----------------- COVER PAGE -----------------
Add-P -text "ZETECH UNIVERSITY" -align "center" -bold $true -size 40 -font "Arial" -spaceBefore 600 -spaceAfter 80
Add-P -text "Inventing the future" -align "center" -bold $false -size 24 -font "Arial" -spaceBefore 0 -spaceAfter 1200
Add-P -text "NETWORK USAGE MONITORING SYSTEM" -align "center" -bold $true -size 36 -font "Arial" -spaceBefore 0 -spaceAfter 100
Add-P -text "SYSTEM DOCUMENTATION" -align "center" -bold $true -size 28 -font "Arial" -spaceBefore 0 -spaceAfter 1400
Add-P -text "SUBMITTED BY," -align "center" -bold $true -size 24 -font "Times New Roman" -spaceBefore 0 -spaceAfter 200
Add-P -text "A SYSTEM DOCUMENTATION SUBMITTED IN PARTIAL FULFILMENT FOR THE AWARD OF DIPLOMA IN COMPUTER SCIENCE BY ZETECH UNIVERSITY" -align "center" -bold $false -size 24 -font "Times New Roman" -spaceBefore 0 -spaceAfter 1200
Add-P -text "AUGUST 2026" -align "center" -bold $true -size 26 -font "Times New Roman" -spaceBefore 0 -spaceAfter 200

Add-PageBreak

# ----------------- DECLARATION -----------------
Add-Heading1 "DECLARATION"
Add-P -text "I Brenda Chebet do declare that this is my original work and it has never been submitted elsewhere for any academic award."
Add-P -text "Student Name: Brenda Chebet Chelule   Sign: _________________   Date: _________" -bold $true -spaceBefore 300 -spaceAfter 200
Add-P -text "Supervisor Name: _________________________   Sign: _________________   Date: __________" -bold $true -spaceBefore 200 -spaceAfter 400

Add-PageBreak

# ----------------- DEDICATION -----------------
Add-Heading1 "DEDICATION"
Add-P -text "This project is dedicated to my family for their constant support, encouragement, and understanding throughout my academic journey. Their motivation and belief in my abilities gave me the strength to complete this project successfully."
Add-P -text "Also, this project is dedicated to all students pursuing knowledge and innovation in the field of computer science."

Add-PageBreak

# ----------------- ABSTRACT -----------------
Add-Heading1 "ABSTRACT"
Add-P -text "This project focuses on the design and development of a Network Usage Monitoring System to improve the efficiency of managing network operations. Many small organizations rely on semi-automated record keeping and manual router checks, which often leads to bandwidth inaccuracies and difficulty in tracking device performance. The developed system provides a digital platform that allows the network administrator to manage device inventory, record usage metrics, and generate reports. The system was developed using PHP with HTML, CSS, JavaScript for the interface and MySQL for the database. The system improves accuracy, enhances network control, and helps the administrator make better decisions through organized and real-time information management."

Add-PageBreak

# ----------------- DEFINITION OF KEY TERMS -----------------
Add-Heading1 "DEFINITION OF KEY TERMS"
Add-P -text "Network Usage Monitoring System - A computerized system used to track, manage, and control network devices and bandwidth utilization, including adding, updating, and monitoring available hardware."
Add-P -text "Database - An organized collection of data stored electronically that allows easy access, management, and updating of information such as device records and metric transactions."
Add-P -text "User Authentication - A security process that verifies the identity of a user by checking login credentials such as a username and password before granting access to the system."
Add-P -text "Dashboard - A graphical user interface that displays key information such as total devices, threshold alerts, and daily traffic to help the user monitor system performance."
Add-P -text "Metric Log - A record that keeps track of all network readings made in the system, including device name, download, upload, date, and latency."
Add-P -text "Threshold Alert - A system notification that warns the user when the bandwidth consumption of a particular device exceeds a predefined limit."
Add-P -text "Entity Relationship Diagram (ERD) - A visual representation that shows how different data entities such as users, devices, metrics, and alerts are related within a database."
Add-P -text "Data Flow Diagram (DFD) - A diagram that illustrates how data moves through the system and how it is processed between different components."
Add-P -text "PHP PDO Framework - A robust server-side scripting environment in PHP used to build the backend logic and secure database access for the network monitoring system."
Add-P -text "Deployment - The process of making the system available for use by hosting it on a server so users can access it through a local network or the internet."

Add-PageBreak

# ----------------- ABBREVIATIONS AND ACRONYMS -----------------
Add-Heading1 "ABBREVIATIONS AND ACRONYMS"
Add-P -text 'API - Application Programming Interface'
Add-P -text 'CSS - Cascading Style Sheets'
Add-P -text 'DFD - Data Flow Diagram'
Add-P -text 'ERD - Entity Relationship Diagram'
Add-P -text 'HTML - Hypertext Markup Language'
Add-P -text 'IDE - Integrated Development Environment'
Add-P -text 'IP - Internet Protocol'
Add-P -text 'ISP - Internet Service Provider'
Add-P -text 'IT - Information Technology'
Add-P -text 'LAN - Local Area Network'
Add-P -text 'MB - Megabyte'
Add-P -text 'Mbps - Megabits Per Second'
Add-P -text 'NOC - Network Operations Center'
Add-P -text 'PDO - PHP Data Objects'
Add-P -text 'PHP - Hypertext Preprocessor'
Add-P -text 'SQL - Structured Query Language'
Add-P -text 'UI - User Interface'
Add-P -text 'URL - Uniform Resource Locator'
Add-P -text 'WAN - Wide Area Network'

Add-PageBreak

# ----------------- TABLE OF CONTENTS -----------------
Add-Heading1 "Table of contents"
$tocItems = @(
    @("DECLARATION", "i"),
    @("DEDICATION", "ii"),
    @("ABSTRACT", "iii"),
    @("DEFINITION OF KEY TERMS", "iv"),
    @("ABBREVIATIONS AND ACRONYMS", "v"),
    @("Table of contents", "vi"),
    @("LIST OF FIGURES", "viii"),
    @("LIST OF TABLES", "ix"),
    @("1. CHAPTER ONE: PROJECT PLANNING AND ANALYSIS", "1"),
    @("1.1. Statement of Problem", "1"),
    @("1.2. Study Justification", "1"),
    @("1.3. System Objectives", "2"),
    @("1.3.1. General Objective", "2"),
    @("1.3.2. Specific Objectives", "2"),
    @("1.4. Functional Requirements", "3"),
    @("1.5. Breakdown of Tools & Resources to Be Used", "4"),
    @("1.6. Gantt chart", "5"),
    @("2. CHAPTER TWO: DESIGN AND MODELING", "6"),
    @("2.1. Introduction to Modelling", "6"),
    @("2.2. User Interface Models", "6"),
    @("2.2.1. Login page", "6"),
    @("2.2.2. Inventory management", "7"),
    @("2.2.3. Sales logs", "7"),
    @("2.2.4. Reports", "8"),
    @("2.3. Logic Models", "8"),
    @("2.3.1. Log in process flowchart", "8"),
    @("2.3.2. System flowchart", "9"),
    @("2.3.3. Data flow diagrams", "10"),
    @("2.3.4. Entity relationship diagram", "11"),
    @("2.3.5. Use case diagram", "12"),
    @("2.3.6. Class diagrams", "13"),
    @("3. CHAPTER THREE: SYSTEM IMPLEMENTATION", "14"),
    @("3.1. Introduction", "14"),
    @("3.2. User Interface Development", "14"),
    @("3.2.1. Login Page Development", "14"),
    @("3.2.2. Dashboard", "16"),
    @("3.2.3. Navigation bar", "18"),
    @("3.2.4. Inventory", "19"),
    @("3.2.5. Add new device form", "20"),
    @("3.2.6. Sales logs", "22"),
    @("3.2.7. Reports", "23"),
    @("3.3. Logic Development", "25"),
    @("3.3.1. Login", "25"),
    @("3.3.2. Dashboard", "26"),
    @("3.3.3. Inventory", "27"),
    @("3.3.4. Sales logs and reports", "29"),
    @("3.4. Testing", "30"),
    @("3.5. Deployment", "31"),
    @("4. CHAPTER FOUR: CONCLUSION AND RECOMMENDATION", "32"),
    @("4.1. Conclusion", "32"),
    @("4.2. Recommendation", "32"),
    @("REFERENCES", "33")
)
Add-TableRows @("Section", "Page") $tocItems

Add-PageBreak

# ----------------- LIST OF FIGURES & TABLES -----------------
Add-Heading1 "LIST OF FIGURES"
Add-P -text "Figure 2.2.1 login page ........................................................................................ 6"
Add-P -text "Figure 2.2.2 inventory management form ................................................................ 7"
Add-P -text "Figure 2.2.3 sales log ........................................................................................... 7"
Add-P -text "Figure 2.2.4 reporting form ..................................................................................... 8"
Add-P -text "Figure 2.3.1 login process flowchart ....................................................................... 8"
Add-P -text "Figure 2.3.2 system flowchart ................................................................................. 9"
Add-P -text "Figure 2.3.3 DFD ................................................................................................... 10"
Add-P -text "Figure 2.3.4 ER Diagram ........................................................................................ 11"
Add-P -text "Figure 2.3.5 use case diagram ................................................................................ 12"
Add-P -text "Figure 2.3.6 class diagram ..................................................................................... 13"
Add-P -text "Figure 3.2.1 login page development ..................................................................... 15"
Add-P -text "Figure 3.2.2 dashboard development ...................................................................... 17"
Add-P -text "Figure 3.2.3 navigation bar .................................................................................... 18"
Add-P -text "Figure 3.2.4 inventory control center ...................................................................... 20"
Add-P -text "Figure 3.2.5 add new device ................................................................................... 21"
Add-P -text "Figure 3.2.6 sales logs ......................................................................................... 22"
Add-P -text "Figure 3.2.7 reports ................................................................................................ 24"
Add-P -text "Figure 3.3.1 PHP-based user authentication function implemented using PDO ........... 25"
Add-P -text "Figure 3.3.2 dashboard backend development ........................................................ 26"
Add-P -text "Figure 3.3.3 inventory backend development ........................................................ 28"
Add-P -text "Figure 3.3.4 sales backend development .............................................................. 29"

Add-Heading1 "LIST OF TABLES"
Add-P -text "Table 1.4.1 functional requirements ...................................................................... 3"
Add-P -text "Table 1.6.1 project schedule breakdown ................................................................ 5"

Add-PageBreak

# ----------------- CHAPTER ONE -----------------
Add-Heading1 "CHAPTER ONE: PROJECT PLANNING AND ANALYSIS"

Add-Heading2 "Statement of Problem"
Add-P -text 'Despite the growth of the digital economy, many small and medium-sized organizations continue to manage their internal network operations using semi-automated methods, such as paper-based logbooks, manual router command lines, and fragmented spreadsheets. These traditional methods present significant operational challenges, including frequent bandwidth inaccuracies, difficulty in tracking historical data usage, and a general lack of centralized security (Laudon and Laudon, 2022).'
Add-P -text 'In the specific network facility under study, NetUsage Hub in Kisii, the absence of a centralized management system has led to critical inefficiencies. Currently, device inventory tracking and bandwidth usage recording are handled manually, leading to human errors and unmonitored traffic spikes. Furthermore, decision-making regarding bandwidth allocation and link restocking is based on administrative guesswork rather than empirical telemetry data. This fragmentation makes it nearly impossible for the administrator to analyze trends, such as identifying top bandwidth-consuming devices or calculating real-time daily traffic. As the volume of networked devices grows, these manual processes become unsustainable, causing operational bottlenecks, network congestion, and potential revenue loss. There is, therefore, a need to develop a centralized, secure internal management portal that automates device tracking, simplifies metric logging, and provides real-time network analytics. Such a system is essential for improving administrative efficiency, ensuring record accuracy, and enabling evidence-based business decisions.'

Add-Heading2 "Study Justification"
Add-P -text 'The development of this project is justified by the critical need for digital transformation within the internal operations of network operations centers and enterprise internet hubs. While the telecommunications sector has modernized, many independent network facilities still struggle with manual record-keeping, leading to bandwidth inconsistencies and unreliable performance reporting (Rashid et al., 2025). This project addresses these gaps by providing an automated, centralized platform for internal management.'
Add-P -text 'From a management perspective, this study is significant as it eliminates the reliance on paper-based ledger systems and unorganized spreadsheets. By implementing a secure internal portal, the network administrator can maintain data integrity through automated status updates and real-time transaction logging. This reduces human error and prevents operational bottlenecks caused by unaccounted traffic or device downtime. Furthermore, the project is justified by its contribution to informed decision-making. The integration of a traffic analytics dashboard allows the administrator to quickly identify top bandwidth-consuming devices and monitor daily usage trends. This shifts the business from a reactive "guesswork" approach to a proactive, data-driven strategy. Ultimately, this system improves overall operational efficiency and ensures that the network hub can scale its internal processes to meet increasing demand without increasing administrative workload.'

Add-Heading2 "System Objectives"
Add-Heading3 "General Objective"
Add-P -text "To develop a network usage monitoring system for NetUsage Hub."

Add-Heading3 "Specific Objectives"
Add-P -text "To develop a device inventory management module for adding, editing and deleting device records, categories and bandwidth limits."
Add-P -text "To develop an automated metric processing mechanism that captures network usage and logs transactions in real-time."
Add-P -text "To implement a threshold alert system that automatically flags devices exceeding configured bandwidth limits."
Add-P -text "To integrate a search functionality for quick retrieval of device details using names, IP addresses or categories."

Add-Heading2 "Functional Requirements"
$funcReqs = @(
    @("Network Administrator", "Sign up and log in", "Log in page"),
    @("Network Administrator", "Add, update and remove device records", "Device inventory management module"),
    @("Network Administrator", "Monitor bandwidth levels and metrics", "Real-time bandwidth monitoring"),
    @("Network Administrator", "Generate inventory and traffic reports", "Traffic and inventory reporting tools"),
    @("Network Administrator", "Make bandwidth allocation and upgrade decisions", "Threshold and limit alerts"),
    @("Network Administrator", "Manage device quotas and configurations", "Quota and configuration management")
)
Add-TableRows @("User", "User Activities", "Features") $funcReqs
Add-Caption "Table 1.4.1 functional requirements"

Add-Heading2 "Breakdown of Tools and Resources to Be Used"
Add-Heading3 "1. Software Tools"
Add-P -text "Full-Stack Framework: PHP - lightweight server-side scripting environment used to handle both front-end integration and back-end logic, including routing, API handling, and security."
Add-P -text "Front-End: HTML, CSS, JavaScript - used for structuring web pages, styling the interface, ensuring responsiveness, and adding interactivity."
Add-P -text "Database: MySQL - a relational database system used for storing application data in a secure, structured format."

Add-Heading3 "2. Development Environment"
Add-P -text "IDE: Visual Studio Code - for writing and managing front-end and back-end code."
Add-P -text "Version Control: Git and GitHub - Git for local version control to track changes in the source code, while GitHub was used as a remote repository for backup, collaboration, and project management."

Add-Heading3 "3. Deployment Resources"
Add-P -text "Application Hosting: XAMPP / Apache Web Server will be used to host the web application and manage the MySQL database in a live local and network environment."
Add-P -text "Application Structure: The front-end will be integrated and served through PHP includes and public assets within the same application."

Add-Heading3 "4. Hardware Resources"
Add-P -text "Client Devices: Desktop computers, laptops and smartphones for accessing and testing the system."
Add-P -text "Server Machine: Local development PC running XAMPP."
Add-P -text "Networking Devices: Internet-enabled devices, routers and switches for system access and telemetry updates."

Add-Heading3 "5. Human Resources"
Add-P -text "System Developer: Responsible for system design, development, testing and documentation."
Add-P -text "Test Users: Classmates and network technicians."
Add-P -text "Project Supervisor: Provides guidance, monitoring, and evaluation throughout the project."

Add-Heading2 "1.6 Project Schedule Breakdown"
Add-Heading3 "Gantt chart"
$gantt = @(
    @("4-8 May", "Done", "", "", "", "", ""),
    @("11-15 May", "Done", "", "", "", "", ""),
    @("18-22 May", "", "Done", "", "", "", ""),
    @("25-29 May", "", "Done", "", "", "", ""),
    @("1-5 Jun", "", "", "Done", "", "", ""),
    @("8-12 Jun", "", "", "Done", "", "", ""),
    @("15-19 Jun", "", "", "Done", "", "", ""),
    @("22-26 Jun", "", "", "Done", "", "", ""),
    @("29-3 Jul", "", "", "", "Done", "", ""),
    @("6-10 Jul", "", "", "", "Done", "", ""),
    @("13-17 Jul", "", "", "", "", "Done", ""),
    @("20-24 Jul", "", "", "", "", "Done", ""),
    @("31st July", "", "", "", "", "", "Done")
)
Add-TableRows @("WEEKS", "Planning", "Design", "Development", "Deployment", "Documentation", "Presentation") $gantt
Add-Caption "Table 1.6.1 project schedule breakdown"

Add-PageBreak

# ----------------- CHAPTER TWO -----------------
Add-Heading1 "CHAPTER TWO: DESIGN AND MODELING"

Add-Heading2 "Introduction to Modelling"
Add-P -text "This chapter presents the system designs and models developed to visualize the proposed network usage monitoring system before the actual implementation began. The diagrams and models illustrate how the system would function, how users would interact with it and how data would flow within the system. Modeling the system prior to development helped to clarify requirements, identify potential challenges early and ensure that all system components are well organized. This approach reduces development errors, improves planning and provides a clear blueprint that guides the implementation process, resulting in an efficient, reliable and a well-structured system."

Add-Heading2 "User Interface Models"
Add-Heading3 "Login page"
$uiLogin = @'
+-------------------------------------------------------------+
|               network usage monitoring system               |
|                                                             |
|           [ Username ]  [________________________]          |
|                                                             |
|           [ Password ]  [________________________]          |
|                                                             |
|                          [  Sign In  ]                      |
+-------------------------------------------------------------+
'@
Add-Code $uiLogin
Add-Caption "Figure 2.2.1 login page"
Add-P -text "The login page illustrates a simple and secure interface where registered administrators enter their username and password to access the system."

Add-Heading3 "Inventory management"
$uiInv = @'
+-----------------------------------------------------------------------------------------+
| [Device Info]     [IP Address]    [Limits]        [Status]         [Action]             |
|                                                                                         |
| Cisco Core Router 192.168.1.1     DL: 5000 MB     Online (High)    Log / Edit / Remove  |
|                                                                                         |
|                                                                    [ Add Device ]       |
+-----------------------------------------------------------------------------------------+
'@
Add-Code $uiInv
Add-Caption "Figure 2.2.2 inventory management form"
Add-P -text "The inventory management form shows how the network administrator can view all devices, monitor status, identify high-usage or offline items and update quotas or configurations, enabling efficient network control and timely maintenance."

Add-Heading3 "Sales logs"
$uiSales = @'
+-----------------------------------------------------------------------------------------+
|                                                                 [ Summary Report ]      |
| [Time]            [Device Name]                       [Download]        [Upload]        |
| 10:35 AM          Cisco Core Router                   1,200 MB          450 MB          |
+-----------------------------------------------------------------------------------------+
'@
Add-Code $uiSales
Add-Caption "Figure 2.2.3 sales log"
Add-P -text "The sales log is a structured table for recording daily metrics. It tracks the time, device polled, download, upload, and total bandwidth. It helps monitor bandwidth, manage inventory, and identify high-consuming devices efficiently."

Add-Heading3 "Reports"
$uiRep = @'
+-----------------------------------------------------------------------------------------+
| [ Total Bandwidth ]                 [ Top Consuming Devices ]                           |
|    4,850 MB                          Device Name               Total MB                 |
|                                      Cisco Core Router         2,450 MB                 |
|                                                                                         |
|                                     [ View Full Logs ]                                  |
+-----------------------------------------------------------------------------------------+
'@
Add-Code $uiRep
Add-Caption "Figure 2.2.4 reporting form"
Add-P -text "The reporting form illustrates how the system generates bandwidth, device, and performance reports, helping the network administrator analyze trends, track heavy traffic users and make informed business decisions."

Add-Heading2 "Logic Models"
Add-Heading3 "Log in process flowchart."
$fcLogin = @'
(Start) --> [Enter Username and Password] --> <Validate Credentials>
                                                    |
                                    [Valid: Yes]    |    [Valid: No]
                                                    v
                                              [Successful] --------> (End)
                                                    |
                                                 [Error] -- (Return to Input)
'@
Add-Code $fcLogin
Add-Caption "Figure 2.3.1 login process flowchart"
Add-P -text "This flowchart illustrates the steps involved when a user logs into the system. It shows how user credentials are entered, validated, authenticated and either granted access or denied based on correctness."

Add-Heading3 "System flow chart"
Add-P -text "The flowchart illustrates how a network usage monitoring system operates from start to finish. The process begins with user login, where the system verifies the user's credentials. If the login is invalid, an error message is displayed; if valid, the user is directed to the dashboard. From there, the user selects an operation such as adding, updating, deleting, or viewing items. Each option allows interaction with the database, where device details are entered, modified, removed, or displayed accordingly. After completing these actions, the system may generate a report based on the inventory data. Finally, the process ends once the user completes their tasks. This flow ensures efficient management, accurate record keeping, and easy access to network telemetry."
Add-Caption "Figure 2.3.2 system flowchart"

Add-Heading3 "Data flow diagrams"
$dfdAscii = @'
[ Network Administrator ]
        | (Login, Device Data, Telemetry Readings)
        v
[ 0. Network Usage Monitoring System ]
        |
        +---> (Stock and Bandwidth Alerts)
        +---> (Reports and Telemetry Data)
'@
Add-Code $dfdAscii
Add-Caption "Figure 2.3.3 DFD"
Add-P -text "The Level 1 Data Flow Diagram illustrates how the network usage monitoring system is divided into four main processes: login, inventory management, metric processing, and report generation. The administrator interacts with the system by entering login details, managing device records, recording metrics, and viewing reports. Each process communicates with specific data stores, namely the User Database, Devices Database, and Usage Database, ensuring proper data storage, retrieval, and system functionality."

Add-Heading3 "Entity relationship diagram"
$erdAscii = @'
[ User ] --< Manages >-- [ Device ] --< Records >-- [ Metric / Alert ]
Attributes: User(user_id, username, password)
            Device(device_id, name, ip, limits, status, category)
            Metric(metric_id, device_id, download, upload, date)
'@
Add-Code $erdAscii
Add-Caption "Figure 2.3.4 ER Diagram"
Add-P -text "The Entity Relationship Diagram (ERD) represents the database structure of the network usage monitoring system. It consists of main entities: User, Device, Metric, and Alert. The User entity stores login credentials for system access. The Device entity contains details about each hardware node, including name, IP address, status, and bandwidth limit. The Metric entity records telemetry details such as download, upload, and recorded date. The relationships show that one user can manage many devices, while each device can be associated with multiple usage logs and alerts. The Metric entity includes a foreign key (device_id) to link each reading to a specific device, ensuring data integrity and proper tracking of transactions."

Add-Heading3 "Use case diagram"
Add-P -text "The use case diagram for the Network Usage Monitoring System illustrates the interactions between the administrator and the system. The actor, represented by a stick figure, can perform several functions within the system boundary, including login, managing devices (adding, editing, deleting), viewing inventory, logging metrics, viewing transaction logs, generating reports, and searching devices. Each functionality is represented as an oval, and lines connecting the actor to the use cases show the interactions. This diagram helps visualize the system's main features and the user's role in performing tasks efficiently."
Add-Caption "Figure 2.3.5 use case diagram"

Add-Heading3 "Class diagrams"
Add-P -text "The class diagram for the Network Usage Monitoring System shows the main classes in the system and how they relate to each other. The User class represents the administrator who can log in and manage operations. The Device class stores details about each hardware device, such as name, IP address, and bandwidth cap. The Metric class records transaction information, including the date and total bytes transferred, and is linked to both the user and the devices monitored. The Report class generates reports based on metric data. The relationships between these classes illustrate how users manage devices, metrics belong to devices, and reports are generated from metrics, providing a clear structure of how the system functions."
Add-Caption "Figure 2.3.6 class diagram"

Add-PageBreak

# ----------------- CHAPTER THREE -----------------
Add-Heading1 "CHAPTER THREE: SYSTEM IMPLEMENTATION"

Add-Heading2 "Introduction"
Add-P -text "This chapter focuses on the implementation of the system, detailing the journey from development to deployment. It begins with the development process, explaining how the design specifications and requirements were transformed into a working application using suitable programming tools, frameworks, and technologies. The chapter then discusses the testing phase, highlighting the methods employed to identify and correct errors, ensure system reliability, and confirm that all functionalities meet user requirements. Finally, it covers the deployment process, describing how the system was prepared for actual use, including installation, configuration, and user accessibility considerations. Throughout the chapter, challenges encountered during each stage are explained along with the solutions applied, providing insight into the practical aspects of system implementation."

Add-Heading2 "User Interface Development"

Add-Heading3 "Login Page Development"
Add-P -text "The login form allows users to securely access the Network Usage Monitoring System by entering a valid username and password. It captures input data, validates user credentials, and authenticates access. Upon successful login, users are granted entry to the system, while incorrect details prompt error messages, ensuring secure and controlled system access."

$loginCode = @'
<!-- Login Form (public/index.php) -->
<form action="index.php" method="POST">
    <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
    <div class="mb-3">
        <label class="form-label small text-muted mb-1">Username</label>
        <div class="input-group">
            <span class="input-group-text bg-light border-end-0"><i class="fa fa-user text-muted"></i></span>
            <input type="text" name="username" class="form-control border-start-0 bg-light" placeholder="Enter username" required autofocus>
        </div>
    </div>
    <div class="mb-4">
        <label class="form-label small text-muted mb-1">Password</label>
        <div class="input-group">
            <span class="input-group-text bg-light border-end-0"><i class="fa fa-lock text-muted"></i></span>
            <input type="password" name="password" class="form-control border-start-0 bg-light" placeholder="Enter password" required>
        </div>
    </div>
    <div class="d-grid">
        <button type="submit" class="btn btn-primary py-2 fw-semibold">Sign In</button>
    </div>
</form>
'@
Add-Code $loginCode

$loginCss = @'
<style>
body {
    background: #f0f2f5;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
}
.login-card {
    width: 100%;
    max-width: 400px;
    border: none;
    border-radius: 8px;
    box-shadow: 0 2px 16px rgba(0, 0, 0, 0.08);
}
.login-logo {
    width: 80px;
    height: 80px;
    object-fit: contain;
    border-radius: 12px;
}
</style>
'@
Add-Code $loginCss
Add-Caption "Figure 3.2.1 login page development"

Add-Heading3 "Dashboard"
Add-P -text "This dashboard provides a clear overview of network performance, showing total devices, threshold alerts, and daily traffic. It also highlights recent additions and offers quick navigation, making network tracking and management efficient and user-friendly."

$dashCode = @'
<!-- dashboard heading and stats -->
<div class="row mb-5">
    <div class="col-md-8">
        <h1 class="fw-bold text-dark">Dashboard Overview</h1>
        <p class="text-muted">Welcome to the internal network usage monitoring system.</p>
    </div>
    <div class="col-md-4 text-md-end">
        <a href="devices.php#add-device-card" class="btn btn-primary px-4"><i class="fa fa-plus me-2"></i>Add Device</a>
    </div>
</div>

<div class="row g-4 mb-5">
    <!-- Total Devices Card -->
    <div class="col-6 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-3 text-center">
                <div class="mb-2 text-primary opacity-75"><i class="fa fa-server fa-2x"></i></div>
                <h6 class="text-muted text-uppercase mb-1 text-primary" style="font-size: 0.7rem; letter-spacing: 0.5px;">Total Inventory</h6>
                <h3 class="fw-bold mb-0 text-dark"><?= $stats['devices'] ?></h3>
            </div>
        </div>
    </div>
    <!-- Alert Card -->
    <div class="col-6 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-3 text-center">
                <div class="mb-2 <?= $stats['alerts'] > 0 ? 'text-danger' : 'text-success' ?> opacity-75">
                    <i class="fa fa-exclamation-triangle fa-2x"></i>
                </div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size: 0.7rem; letter-spacing: 0.5px;">Threshold Alerts</h6>
                <h3 class="fw-bold mb-0 <?= $stats['alerts'] > 0 ? 'text-danger' : 'text-success' ?>"><?= $stats['alerts'] ?></h3>
            </div>
        </div>
    </div>
    <!-- Today's Traffic Card -->
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-3 text-center">
                <div class="mb-2 text-success opacity-75"><i class="fa fa-bar-chart fa-2x"></i></div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size: 0.7rem; letter-spacing: 0.5px;">Today's Traffic</h6>
                <h3 class="fw-bold mb-0 text-success"><?= number_format($stats['today_mb'], 1) ?> MB</h3>
            </div>
        </div>
    </div>
</div>
'@
Add-Code $dashCode
Add-Caption "Figure 3.2.2 dashboard development"

Add-Heading3 "Navigation bar"
Add-P -text "This navigation bar provides quick access to key sections like Books/Devices, Inventory, Sales/Metric Logs, and Reports. It also includes a search function and user profile controls, ensuring easy navigation and efficient system interaction."

$navCode = @'
<!-- navbar -->
<nav class="navbar navbar-expand-lg navbar-white bg-white border-bottom sticky-top">
    <div class="container-fluid px-4">
        <a class="navbar-brand fw-bold d-flex align-items-center" href="dashboard.php" style="font-size: 1.75rem;">
            <span class="brand-badge me-2"><i class="fa fa-wifi text-primary"></i></span>
            <span class="text-dark">Net-</span><span class="text-primary">Portal</span>
        </a>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0 fw-semibold ms-4">
                <li class="nav-item"><a class="nav-link text-primary active" href="dashboard.php">Dashboard</a></li>
                <li class="nav-item"><a class="nav-link" href="devices.php">Inventory</a></li>
                <li class="nav-item"><a class="nav-link" href="metrics.php">Metric Logs</a></li>
                <li class="nav-item"><a class="nav-link" href="reports.php">Reports</a></li>
            </ul>
            <form class="d-flex ms-3" action="devices.php" method="GET" style="min-width: 350px;">
                <div class="input-group">
                    <input class="form-control bg-light border-secondary border-opacity-25" type="search" name="q" placeholder="Search devices, IP..." required>
                    <button class="btn btn-primary px-3" type="submit"><i class="fa fa-search"></i></button>
                </div>
            </form>
            <div class="ms-3 d-none d-lg-flex align-items-center">
                <span class="text-muted small me-2"><i class="fa fa-user-circle me-1"></i> <?= e(user()['full_name']) ?></span>
                <a href="logout.php" class="btn btn-sm btn-outline-secondary px-3">Logout</a>
            </div>
        </div>
    </div>
</nav>
'@
Add-Code $navCode
Add-Caption "Figure 3.2.3 navigation bar"

Add-Heading3 "Inventory"
Add-P -text "This inventory control center displays detailed device information including limits, operational status, and categories. It allows quick actions like logging, editing, or deleting items, while highlighting threshold alerts to help maintain efficient network management."

$invCode = @'
<div class="row">
    <div class="col-lg-9 mb-4">
        <div class="card shadow-sm border-0">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-dark">
                    <tr>
                        <th class="ps-3">Device Info</th>
                        <th>IP Address</th>
                        <th>Limits (MB)</th>
                        <th>Status</th>
                        <th>Category</th>
                        <th class="text-center">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- Dynamic rows matching template -->
                </tbody>
            </table>
        </div>
    </div>
    <!-- Threshold / Low Stock Sidebar -->
    <div class="col-lg-3">
        <div class="card shadow-sm border-0 mb-4 position-sticky" style="top: 80px;">
            <div class="card-header bg-danger text-white fw-bold">Threshold Alert</div>
            <div class="card-body p-0">
                <!-- Dynamic alert list group -->
            </div>
        </div>
    </div>
</div>
'@
Add-Code $invCode
Add-Caption "Figure 3.2.4 inventory control center"

Add-Heading3 "Add new device form"
Add-P -text "The Add New Device form is a data-entry interface designed for adding new hardware titles to the inventory database. It uses a clean, grid-based layout to ensure all required metadata is captured quickly."

$addDevCode = @'
<!-- New Device Card (public/devices.php) -->
<div class="card border mobile-full-width shadow-sm">
    <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
        <h5 class="mb-0 fw-bold"><i class="fa fa-plus-circle me-2 text-primary"></i>New Device</h5>
        <a href="devices.php" class="btn-close" aria-label="Close"></a>
    </div>
    <div class="card-body p-3">
        <form action="devices.php" method="POST">
            <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
            <input type="hidden" name="action" value="save">
            <div class="mb-2">
                <label class="form-label small text-muted mb-1">Device Name</label>
                <input type="text" name="name" class="form-control form-control-sm" placeholder="Enter Full Device Name" required>
            </div>
            <div class="row g-2 mb-2">
                <div class="col-6">
                    <label class="form-label small text-muted mb-1">IP Address</label>
                    <input type="text" name="ip_address" class="form-control form-control-sm" placeholder="192.168.1.1" required>
                </div>
                <div class="col-6">
                    <label class="form-label small text-muted mb-1">Location</label>
                    <input type="text" name="location" class="form-control form-control-sm" placeholder="Server Room" required>
                </div>
            </div>
            <div class="row g-2 mb-3">
                <div class="col-4">
                    <label class="form-label small text-muted mb-1">DL Limit</label>
                    <input type="number" name="download_limit_mb" class="form-control form-control-sm" value="5000" required>
                </div>
                <div class="col-4">
                    <label class="form-label small text-muted mb-1">UL Limit</label>
                    <input type="number" name="upload_limit_mb" class="form-control form-control-sm" value="2000" required>
                </div>
                <div class="col-4">
                    <label class="form-label small text-muted mb-1">Category</label>
                    <select name="device_type" class="form-select form-select-sm">
                        <option value="Router">Router</option>
                        <option value="Switch">Switch</option>
                        <option value="Access Point">Access Point</option>
                        <option value="Firewall">Firewall</option>
                    </select>
                </div>
            </div>
            <div class="d-grid">
                <button type="submit" class="btn btn-primary btn-sm block">Add Device to Inventory</button>
            </div>
        </form>
    </div>
</div>
'@
Add-Code $addDevCode
Add-Caption "Figure 3.2.5 add new device"

Add-Heading3 "Sales logs"
Add-P -text "The Real-Time Transaction Logs section provides an automated audit trail of all network metrics and bandwidth changes. It is designed to give administrators an immediate, high-level view of daily operations without needing to generate manual reports."

$logsCode = @'
<!-- Desktop Table View (public/metrics.php) -->
<div class="table-responsive">
    <table class="table table-hover align-middle mb-0">
        <thead class="table-dark">
            <tr>
                <th class="ps-3">Time</th>
                <th>Device Name</th>
                <th class="text-center">Qty (MB)</th>
                <th class="text-end pe-3">Total Bandwidth</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($metrics as $m): ?>
                <tr>
                    <td class="ps-3 text-muted">
                        <div class="d-flex flex-column">
                            <span class="fw-bold text-dark"><?= date('H:i', strtotime($m['recorded_at'])) ?></span>
                            <small><?= date('d/m', strtotime($m['recorded_at'])) ?></small>
                        </div>
                    </td>
                    <td><span class="fw-bold"><?= e($m['device_name']) ?></span></td>
                    <td class="text-center"><?= number_format($m['download_mb'], 2) ?></td>
                    <td class="text-end pe-3 text-success fw-bold"><?= number_format($m['total_mb'], 2) ?> MB</td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
'@
Add-Code $logsCode
Add-Caption "Figure 3.2.6 sales logs"

Add-Heading3 "Reports"
Add-P -text "The Reports Center provides a comprehensive summary of network performance, including bandwidth trends, traffic analysis, and device movement. It helps users generate insights, track progress over time, and make informed decisions through organized and easy-to-read reports."

$repCode = @'
<div class="row mb-5">
    <div class="col-md-4 mb-4">
        <div class="card border-0 shadow h-100">
            <div class="card-body py-4 text-center">
                <div class="mb-2 text-success opacity-75"><i class="fa fa-area-chart fa-2x"></i></div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size: 0.7rem; letter-spacing: 0.5px;">Total Bandwidth Generated</h6>
                <h3 class="fw-bold mb-0 text-success"><?= number_format($totalBandwidth, 1) ?> MB</h3>
            </div>
        </div>
    </div>
    <div class="col-md-8 mb-4">
        <div class="card border-0 shadow h-100">
            <div class="card-header bg-white border-bottom p-3">
                <h5 class="mb-0 fw-bold">Top Bandwidth Devices</h5>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr><th class="ps-4">Device Name</th><th class="text-end pe-4">Total MB</th></tr>
                    </thead>
                    <tbody><!-- Dynamic list --></tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<div class="card border-0 shadow mb-5">
    <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
        <h5 class="mb-0 fw-bold">Recent Activity</h5>
        <a href="metrics.php" class="btn btn-sm btn-outline-primary px-3">View Full Logs</a>
    </div>
    <div class="card-body p-3 text-center">
        <p class="text-muted mb-3">View detailed records of every metric reading including Times, device IDs, and traffic values.</p>
        <a href="metrics.php" class="btn btn-primary px-4">Access Transaction Ledger</a>
    </div>
</div>
'@
Add-Code $repCode
Add-Caption "Figure 3.2.7 reports"

Add-Heading2 "Logic Development"

Add-Heading3 "Login"
Add-P -text "The login process uses a standard PHP PDO workflow. It first checks if a user is already authenticated; if so, it redirects them to the dashboard. For new login attempts, the system extracts the username and password from a POST request, searches the database for a matching user, and verifies the password hash. If the credentials are valid, it initializes a session and redirects the user to their intended destination. If authentication fails, it triggers an error message and reloads the login template."

$phpLogin = @'
// authentication function (includes/auth.php)
function attempt_login(string $username, string $password): bool {
    $stmt = db()->prepare('SELECT * FROM users WHERE username = ? LIMIT 1');
    $stmt->execute([$username]);
    $record = $stmt->fetch();
    if ($record && password_verify($password, $record['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['user'] = ['id' => $record['id'], 'username' => $record['username'], 'full_name' => $record['full_name'], 'role' => $record['role']];
        return true;
    }
    return false;
}
'@
Add-Code $phpLogin
Add-Caption "Figure 3.3.1 PHP-based user authentication function implemented using PDO"

Add-Heading3 "Dashboard"
Add-P -text "The /logout route requires the user to be logged in, logs them out, shows a success message with session flash, and then redirects them to the login page. The dashboard route also requires login and displays summary statistics: it counts the total number of devices, counts active threshold alerts, calculates today's total traffic using a database aggregate function (sum of download and upload filtered by today's date), retrieves the most recently added devices, and passes all this data to the dashboard template for rendering."

$phpDash = @'
// dashboard metrics (public/dashboard.php)
$stats = [
    'devices' => (int)db()->query('SELECT COUNT(*) FROM devices')->fetchColumn(),
    'online' => (int)db()->query("SELECT COUNT(*) FROM devices WHERE status='online'")->fetchColumn(),
    'alerts' => (int)db()->query('SELECT COUNT(*) FROM alerts WHERE is_resolved=0')->fetchColumn(),
    'today_mb' => (float)db()->query('SELECT COALESCE(SUM(download_mb + upload_mb),0) FROM usage_metrics WHERE DATE(recorded_at)=CURDATE()')->fetchColumn()
];
$devices = db()->query('SELECT * FROM devices ORDER BY id DESC LIMIT 8')->fetchAll();
'@
Add-Code $phpDash
Add-Caption "Figure 3.3.2 dashboard backend development"

Add-Heading3 "Inventory"
Add-P -text "The /inventory route displays all devices and highlights threshold items. The add route allows logged-in users to create a new device by submitting a form, saving it to the database, and redirecting to the inventory page with a success message. The edit route lets users update an existing device's details, pre-filling the form and saving changes to the database. The delete route deletes a device (and its related records) from the database. The quick_log route updates traffic, records the metric, and triggers threshold alerts when limits are exceeded. Finally, the search route allows users to search devices by name, IP, or type using a query and displays the matching results."

$phpInv = @'
// inventory operations (public/devices.php)
if ($action === 'save') {
    $id = (int)($_POST['id'] ?? 0);
    $data = [trim($_POST['name']), trim($_POST['ip_address']), trim($_POST['device_type']), trim($_POST['location']), $_POST['status'], (float)$_POST['download_limit_mb'], (float)$_POST['upload_limit_mb']];
    if ($id) {
        $data[] = $id;
        db()->prepare('UPDATE devices SET name=?, ip_address=?, device_type=?, location=?, status=?, download_limit_mb=?, upload_limit_mb=? WHERE id=?')->execute($data);
    } else {
        db()->prepare('INSERT INTO devices (name, ip_address, device_type, location, status, download_limit_mb, upload_limit_mb, last_seen) VALUES (?,?,?,?,?,?,?,NOW())')->execute($data);
    }
} elseif ($action === 'delete') {
    db()->prepare('DELETE FROM devices WHERE id=?')->execute([(int)$_POST['id']]);
}
'@
Add-Code $phpInv
Add-Caption "Figure 3.3.3 inventory backend development"

Add-Heading3 "Sales logs and reports"
Add-P -text "This PHP code defines two authenticated pages. The transaction logs route retrieves all metric records from the database, ordered by recorded_at in descending order, and passes them to the template for display. The reports route generates summary data: it calculates the total bandwidth by summing usage_metrics, and finds the top best-selling / consuming devices by summing traffic per device, grouping by device id, ordering by total in descending order. These results are then rendered in the reports template."

$phpRep = @'
// metric and reporting backend (public/reports.php)
$stmtTotal = db()->prepare('SELECT COALESCE(SUM(download_mb + upload_mb),0) FROM usage_metrics WHERE recorded_at BETWEEN ? AND ?');
$stmtTotal->execute([$from.' 00:00:00', $to.' 23:59:59']);
$totalBandwidth = (float)$stmtTotal->fetchColumn();

$stmtTop = db()->prepare('SELECT d.name, SUM(m.download_mb + m.upload_mb) AS total_mb 
    FROM usage_metrics m JOIN devices d ON d.id=m.device_id 
    WHERE m.recorded_at BETWEEN ? AND ? GROUP BY d.id ORDER BY total_mb DESC LIMIT 5');
$stmtTop->execute([$from.' 00:00:00', $to.' 23:59:59']);
$topDevices = $stmtTop->fetchAll();
'@
Add-Code $phpRep
Add-Caption "Figure 3.3.4 sales backend development"

Add-Heading2 "Testing"
Add-P -text "User Login Feature" -bold $true
Add-P -text "Testing Action: I attempted to log in using both valid and invalid credentials to verify whether access was granted correctly and error messages were displayed."
Add-P -text "Result: The system allowed correct login but initially did not show an error for incorrect credentials."
Add-P -text "Correction: I updated the login validation code to display an appropriate error message when credentials are invalid."

Add-P -text "Inventory Entry Form" -bold $true
Add-P -text "Testing Action: I added sample products to the inventory to check if the details were correctly saved to the database."
Add-P -text "Result: Correctly saved."

Add-P -text "Sales Log Recording" -bold $true
Add-P -text "Testing Action: I recorded sample metric transactions to verify that the system updated inventory quantities and calculated totals correctly."
Add-P -text "Result: The system initially did not evaluate threshold alerts after a metric record."
Add-P -text "Correction: I fixed the threshold evaluation logic so that alerts automatically trigger when limit is exceeded."

Add-P -text "Report Generation" -bold $true
Add-P -text "Testing Action: I generated inventory and bandwidth reports for different dates to check the accuracy of totals and summaries."
Add-P -text "Result: Some entries were missing due to incorrect date filtering."
Add-P -text "Correction: I corrected the filtering logic, and all relevant data now appears in the reports."

Add-P -text "System Navigation and Buttons" -bold $true
Add-P -text "Testing Action: I navigated through all menus and clicked buttons to verify that each directed to the correct page or performed the intended action."
Add-P -text "Result: Worked perfectly."

Add-Heading2 "Deployment"
Add-P -text "The Network Usage Monitoring System has been successfully deployed on XAMPP and Apache web server, providing a reliable and accessible web-based platform for managing network inventory. Apache offers a local and intranet hosting environment, which ensures the application runs continuously without dependency on external public cloud servers. The deployment process involved placing the project in the htdocs root, configuring the MySQL database with required tables, and setting up the web app with the correct configuration parameters. This deployment enables users to access the system from any device with network connectivity, ensuring real-time inventory tracking, seamless data management, and efficient operational workflows, all hosted securely in the network."
Add-P -text "Access the live system here: Network Usage Monitoring System (NetUsage Hub)" -bold $true

Add-PageBreak

# ----------------- CHAPTER FOUR -----------------
Add-Heading1 "CHAPTER FOUR: CONCLUSION AND RECOMMENDATION"

Add-Heading2 "Conclusion"
Add-P -text "The aim of this project was to develop a Network Usage Monitoring System that improves the efficiency of managing network operations. Chapter One discussed the problem statement, justification of the study, and the objectives of the system. It highlighted the challenges faced by network hubs that rely on manual record keeping such as bandwidth inaccuracies and difficulty in tracking device performance. Chapter Two focused on the design and modelling of the system using diagrams such as the Data Flow Diagram, Entity Relationship Diagram, Use Case Diagram, and Class Diagram to illustrate how the system operates. Chapter Three described the implementation of the system including the development of the user interface, logic implementation using the PHP and MySQL framework, system testing, and deployment."
Add-P -text "The developed system successfully automates important network operations including device inventory management, metric logging, and report generation. The system helps the network administrator track bandwidth levels, record transactions, and generate reports for better decision making. During the development of this project, I gained new knowledge in web development using PHP, database management using MySQL, and system deployment using local server platforms. However, some challenges were encountered such as debugging code errors and ensuring proper integration between the front-end and back-end components. These challenges helped improve my problem-solving and programming skills."

Add-Heading2 "Recommendation"
Add-P -text "Although the Network Usage Monitoring System functions effectively, there are several improvements that future developers can implement to enhance its capabilities. One improvement would be integrating automated SNMP device polling so that network metrics can be gathered automatically instead of relying on manual entry."
Add-P -text "Another improvement would be the integration of SMS and email notification technology. This would allow critical threshold alerts to be dispatched immediately to technicians' mobile phones, thereby improving response time and reducing network downtime."
Add-P -text "Future developers may also consider upgrading the system database to a distributed cluster to support larger amounts of telemetry data and multiple concurrent users. Additionally, the system can be enhanced by implementing advanced analytics and graphical reports that provide deeper insights into traffic patterns and network performance."

Add-PageBreak

# ----------------- REFERENCES -----------------
Add-Heading1 "REFERENCES"
Add-P -text "Djohan, T., and Stefvy. (2023, April). 'Inventory Shortages and Poor Management Systems Negatively Affect Customer Satisfaction in the Retail and Infrastructure Industry'. Research Synergy Press Journals. https://www.researchgate.net/publication/371763839"
Add-P -text "International Telecommunication Union (ITU). (2023). Measuring digital development: Facts and figures 2023. https://www.itu.int/en/Pages/default.aspx"
Add-P -text "Laudon, K. C., and Laudon, J. P. (2022). Management information systems: Managing the digital firm (17th ed.). Pearson Education."
Add-P -text "Mhlongo, N. et al. (2024, February 6). 'Reviewing the impact of cloud computing on small and medium enterprises in Africa'. International journal of science and research Archive. https://ijsra.net/sites/default/files/IJSRA-2024-0236.pdf?utm"
Add-P -text "Rashid et al. (2025, July 18). 'A Review of Technological Advancements and Operational Improvements in IoT for Retail Inventory Management'. IJRISS. https://rsisinternational.org/journals/ijriss/articles/a-review-of-technological-advancements-and-operational-improvements-in-iot-for-retail-inventory-management/"

# Close body and document with strict section properties (w:sectPr)
[void]$sb.Append(@'
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
      <w:cols w:space="720"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>
'@)

[System.IO.File]::WriteAllText("$tempDir\word\document.xml", $sb.ToString(), $utf8NoBom)

# 6. Compress into .docx using ZipArchive with EXPLICIT FORWARD SLASHES (/)
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

$zipStream = New-Object System.IO.FileStream($outputDocx, [System.IO.FileMode]::Create)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

$allFiles = Get-ChildItem -Path $tempDir -Recurse -File
foreach ($file in $allFiles) {
    # Calculate relative path and FORCE forward slash '/'
    $relPath = $file.FullName.Substring($tempDir.Length + 1).Replace("\", "/")
    $entry = $archive.CreateEntry($relPath, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $entryStream.Write($fileBytes, 0, $fileBytes.Length)
    $entryStream.Dispose()
}

$archive.Dispose()
$zipStream.Dispose()

# Copy to public folder
Copy-Item -Path $outputDocx -Destination $publicDocx -Force

# Cleanup
Remove-Item -Recurse -Force $tempDir

Write-Host "SUCCESS: Generated 100% valid OpenXML Microsoft Word Document (.docx) at:"
Write-Host "  $outputDocx"
