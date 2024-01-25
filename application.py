from flask import Flask
application = Flask(__name__)

@application.route('/')
def hello_world():
    html = """
    <html>
        <head>
            <title>Hello World App</title>
            <style>
                body {
                    background-color: #f0f0f0; /* Cambia el color de fondo */
                    text-align: center; /* Centra el texto */
                    padding-top: 100px; /* Agrega espacio en la parte superior */
                }
                h1 {
                    color: #333; /* Cambia el color del texto */
                }
            </style>
        </head>
        <body>
            <h1>Hello, World!</h1>
        </body>
    </html>
    """
    return html