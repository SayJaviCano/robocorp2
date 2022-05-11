*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Desktop
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Cloud.Azure
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault

*** Tasks ***
Pedir robots de RobotSpareBin Industries Inc
    Abrir la web de pedidos de robots
    ${pedidos}=    Cargar pedidos
    FOR    ${pedido}    IN    @{pedidos}
        Aceptar aviso legal
        Rellenar el formulario    ${pedido}
        Ver robot
        Enviar pedido
        ${pdf}=    Guardar cada recibo como un PDF    ${pedido}[Order number]
        ${screenshot}=    Tomar una captura de la imagen del robot    ${pedido}[Order number]
        Incrustar la imagen del robot con el PDF del recibo    ${screenshot}    ${pdf}    ${pedido}[Order number]
        Pedir otro
    END
    Crear un ZIP con los pedidos

*** Keywords ***
Abrir la web de pedidos de robots
    ${secret}    Get Secret    robot2
    Open Available Browser    ${secret}[url]
    # Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Aceptar aviso legal
    ${aceptar_aviso_legal}    Is Element Visible    class:btn-dark
    IF    ${aceptar_aviso_legal} == ${TRUE}
        Click Button    class:btn-dark
    END

Cargar pedidos
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true
    ${pedidos}=    Read table from CSV    orders.csv
    [Return]    ${pedidos}

Rellenar el formulario
    [Arguments]    ${pedido}
    ${formulario_pedidos}=    Is Element Visible    preview
    IF    ${formulario_pedidos} == ${FALSE}
        Click Button    Ver robot
    END
    Select From List By Value    head    ${pedido}[Head]
    Select Radio Button    body    ${pedido}[Body]
    Input Text    class:form-control    ${pedido}[Legs]
    Input Text    address    ${pedido}[Address]

Ver robot
    Click Button    preview

Enviar pedido
    Click Button    order
    FOR    ${i}    IN RANGE    10
        ${existe_error}=    Is Element Visible    class:alert-danger
        IF    ${existe_error} == ${TRUE}
            Click Button    order
        END
        Exit For Loop If    ${existe_error} == ${FALSE}
    END

Guardar cada recibo como un PDF
    [Arguments]    ${Order number}
    ${order_receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    pedidos/OrderNumber${Order number}.pdf
    [Return]    pedidos/OrderNumber${Order number}.pdf

Tomar una captura de la imagen del robot
    [Arguments]    ${Order number}
    ${robot_number}=    Catenate    SEPARATOR=    RobotScreenshot    ${Order number}
    Screenshot    robot-preview-image    pedidos/${robot_number}.png
    [Return]    pedidos/${Order number}.png

Pedir otro
    Click Button    order-another

Incrustar la imagen del robot con el PDF del recibo
    [Arguments]    ${screenshot}    ${pdf}    ${Order number}
    Add Watermark Image To PDF
    ...    image_path=pedidos/RobotScreenshot${Order number}.png
    ...    source_path=pedidos/OrderNumber${Order number}.pdf
    ...    output_path=pedidos/RobotOrder${Order number}.pdf

 Crear un ZIP con los pedidos
    Archive Folder With Zip    pedidos    pedidos/pedidos.zip    include=RobotOrder*
