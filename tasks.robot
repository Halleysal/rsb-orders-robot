*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets

*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

*** Keywords ***
Get orders
    ${file_path}=    Get Secret    paths
    Download    ${file_path}[excel]    overwrite=True
    ${table}=    Read table from CSV    orders.csv     header=True
    [Return]    ${table}

*** Keywords ***
Close the annoying modal
    Click Button When Visible    class:btn-warning

*** Keywords ***
Fill the form
    [Arguments]    ${order}
    Select From List By Index    class:custom-select    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    
*** Keywords ***
Preview the robot
    Click Button When Visible    id:preview

*** Keywords ***
Submit the order
    Click Button When Visible    id:order
    Wait Until Page Contains Element    id:receipt

*** Keywords ***
Store the receipt as a PDF file 
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt    
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}receipt-${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}receipt-${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    Set Screenshot Directory    ${OUTPUT_DIR}${/}screenshots
    ${screenshot}    Set Variable    screenshot-${order_number}.png 
    Capture Element Screenshot    id:robot-preview-image    ${screenshot}
    [Return]    ${OUTPUT_DIR}${/}screenshots${/}${screenshot}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${images}=    Create List    ${screenshot}
    Add Files To Pdf    ${images}    ${pdf}    true

*** Keywords ***
Go to order another robot
    Click Button When Visible    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip

Get user Input
    Add heading    Set site URL
    Add text input    url    label=Site URL
    ${result}=    Run dialog
    [Return]    ${result.url}    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Get user Input    
    Open the robot order website    ${url}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts