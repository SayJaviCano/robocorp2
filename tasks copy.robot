*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Desktop
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Cloud.Azure
Library           RPA.PDF

*** Tasks ***
Pedir robots de RobotSpareBin Industries Inc
    Abrir la web de pedidos de robots
    ${pedidos}=    Cargar pedidos
    FOR    ${pedido}    IN    @{pedidos}
        Aceptar aviso legal
        Rellenar el formulario    ${pedido}
        Ver robot
        Enviar pedido
        # ${numero_recibo} =    Get Text    css:h3
        # ${pdf}=    Guardar cada recibo como un PDF    ${pedido}[Order number]
        # # ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        # # Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Pedir otro
    END

*** Keywords ***
Abrir la web de pedidos de robots
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Aceptar aviso legal
    ${aceptar_aviso_legal}    Is Element Visible    class:btn-dark
    IF    ${aceptar_aviso_legal} == ${TRUE}
        Click Button    class:btn-dark
    END

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
    FOR    ${i}    IN RANGE    10
        ${existe_error}=    Is Element Visible    class:alert-danger
        IF    ${existe_error} == ${TRUE}
            Click Button    preview
        END
        Exit For Loop If    ${existe_error} == ${FALSE}
    END

Enviar pedido
    Click Button    order
    # FOR    ${i}    IN RANGE    10
    #    ${existe_error}=    Is Element Visible    class:alert-danger
    #    IF    ${existe_error} == ${TRUE}
    #    Click Button    order
    #    END
    #    Exit For Loop If    ${existe_error} == ${FALSE}
    # END

Guardar cada recibo como un PDF
    # Ver si puedo guardarlo con el número de recibo real
    [Arguments]    ${Order number}
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    pedidos/OrderNumber${Order number}.pdf
    [Return]    pedidos/OrderNumber${Order number}.pdf
# Guardar cada recibo como un PDF
#    # Hay que ver si puedo guardarlo con el número de recibo real
#    [Arguments]    ${Order number}
#    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
#    Html To Pdf    ${order_receipt_html}    pedidos/OrderNumber${Order number}.pdf
#    [Return]    pedidos/OrderNumber${Order number}.pdf

Pedir otro
    Click Button    order-another

Cargar pedidos
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true
    ${pedidos}=    Read table from CSV    orders.csv
    [Return]    ${pedidos}
