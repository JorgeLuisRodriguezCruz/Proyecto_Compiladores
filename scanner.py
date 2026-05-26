""" 
Scanner PasCat - Analizador Léxico para el Lenguaje de Programación PasCat
Autores: 
- Jorge Luis Rodríguez Cruz - 2020010773
- Franco Vinicio Rojas Lagos - 2022437823
Descripción: Este módulo implementa el analizador léxico para el lenguaje de programación PasCat.
Funcionalidades:
- Tokenización de código fuente PasCat, identificando palabras reservadas, identificadores, literales y símbolos.
- Manejo de comentarios de línea y bloque, con conteo estadístico.
- Generación de un "Muro de Ladrillos" en HTML que visualiza los tokens encontrados, con colores según su familia.
- Estadísticas detalladas de la compilación, incluyendo conteo de caracteres, líneas, comentarios y errores léxicos.
Uso: Ejecutar el script pasando el archivo fuente PasCat como argumento
Ejemplo: python scanner.py ejemplo.cat
Salida: Archivo 'muro.html' con la visualización del
tokens y las estadísticas de compilación.
"""

import sys
import html

# ==========================================
# DICCIONARIO DE TOKENS Y FAMILIAS (V1.3)
# ==========================================
TOKENS = {
    'ID': 10, 'ID_FUNC': 11, 'ID_OP_ARIT': 12, 'ID_OP_CAR': 13,
    'ID_OP_LOG': 14, 'ID_OP_STR': 15, 'ID_OP_CONJ': 16, 'ID_OP_COM': 17, 'ID_OP_CREAT': 18,
    'ID_ATRIBUTO': 19,
    'LIT_OVEJA': 20, 'LIT_HUELLA': 21, 'LIT_SERPIENTE': 22, 'LIT_GATO': 23, 'LIT_COLM': 24,
    
    # Familia 2: Estructura, Control y Nombres de bloques
    'REINO': 100, 'MUERTE': 101, 'RESERVA': 102, 'ESPECIES': 103,
    'ORGANISMOS': 104, 'HUEVOS': 105, 'PROCESOS': 106, 'COMPORTAMIENTOS': 107, 
    'ENTRADA': 108, 'NACIMIENTO': 109,
    'PLANCTON': 110, 'DELFIN': 111, 'PULPO': 112, 'CABEZA': 113, 'TENTACULO': 114,
    'TORTUGA': 115, 'DODO': 116, 'PERRO': 117, 'LIEBRE': 118,
    'TIBURON': 120, 'SANGRE': 121, 'CORTEJO': 122, 'ATRAE': 123, 'REPELE': 124,
    'LORO': 125, 'MUDO': 126, 'MIGRAR': 127, 'DESDE': 128, 'HASTA': 129, 'PASO': 130, 'RUTA': 131,
    'ENTRENAR': 132, 'RITUAL': 133, 'CANGURO': 134, 'BOLSA': 135, 'INSTRUCCION': 136,
    
    # Familia 3: Tipos de Datos y Declaradores
    'OVEJA': 200, 'HUELLA': 201, 'SERPIENTE': 202, 'GATO': 203,
    'COLMENA': 204, 'PALOMA': 205, 'MEDUSA': 206, 'CORRAL': 207, 'QUEBRANTAHUESOS': 208, 'QUIMERA': 209,
    'FOSIL': 220, 'CRIPSIS': 221, 'HABITA': 222, 'ADOPTA': 223, 'PELIGRO': 224,
    
    # Familia 4: Operadores Especiales y Biológicos
    'CAMALEON': 400, 'BALLENA': 401, 'MACHETEAR': 410, 'TROZO': 411, 'ACECHAR': 412,
    'ABEJA': 420, 'AGUIJON': 421, 'ENJAMBRE': 422, 'MIEL': 423, 'FAMILIA': 424,
    'PRESA': 430, 'DEPREDADOR': 431, 'ESCAMAS': 433, 'ENROSCAR': 434, 
    'MUDAR': 435, 'PIEL': 436, 'CLON': 437, 'ACARICIAR': 438,
    'AMARRAR': 440, 'LIGO': 441, 'ALETEAR': 442, 'NIDO': 443, 
    
    # Operadores Aritméticos V1.3
    'BOA': 444, 'CAN': 445, 'EMU': 446, 'GNU': 447, 'YAK': 448, # Enteros
    'FOCA': 449, 'MERO': 450, 'ORCA': 451, 'RAYA': 452,         # Flotantes
    
    'SIM': 453, 'MUT': 454, 'DEP': 455, 'COM': 456,
    'HIBRIDO': 457, 'PRESACLON': 458, 'DEPREDADORCLON': 459, 'ATERRIZAR': 460, 
    'PLUMA': 461, 'CAPTURAR': 462, 'REPRENDER': 463, 'RENACER': 464, 'TRANSFORMAR': 465, 
    
    # Operadores Creativos
    'CONEJO': 470, 'OSO_COME': 471, 'PANDA_COME': 472,
    
    # Familia 5: Funciones Intrínsecas (E/S y Utilitarias)
    'ESCONEJO?': 520, 'ESLOBO?': 521, 'DESOLADO?': 522, 'SALVAJE': 523, 'DOCIL': 524,
    'RUGIROVEJA': 530, 'RUGIRHUELLA': 531, 'RUGIRSERPIENTE': 532, 'RUGIRGATO': 533,
    'OLEROVEJA': 540, 'OLERHUELLA': 541, 'OLERSERPIENTE': 542, 'OLERGATO': 543,
    
    # Símbolos, Asignaciones y Referencias
    'SEP_SECCION': 300, # ~~
    'SEP_INSTRUCCION': 301, # ~
    'ASIGNACION': 302, # =
    'DECLARACION': 303, # <-
    'REF_PARAM': 304, # ><>
    'DOS_PUNTOS': 305, # :
    'PAR_ABRE': 310, # (
    'PAR_CIERRA': 311, # )
    'COR_ABRE': 312, # [
    'COR_CIERRA': 313, # ]
    'COMA': 314, # ,
    'ACCESO_REG': 315, # @
    'MENOR_QUE': 316, # <
    'MAYOR_QUE': 317, # >
    'SUMA': 318, # +
    'MULTIPLICACION': 319, # *
    'LLAVE_ABRE': 320, # {
    'LLAVE_CIERRA': 321, # }
    'DESP_DER': 322, # >>
    'DOLAR': 323, # $
    
    # Comentarios y Errores
    'COM_LINEA': 900,
    'COM_BLOQUE': 901,
    'EOF': -1,
    'ERROR_LEXICO': 999
}

PALABRAS_RESERVADAS = {
    'reino': TOKENS['REINO'], 'muerte': TOKENS['MUERTE'], 'reserva': TOKENS['RESERVA'],
    'especies': TOKENS['ESPECIES'], 'organismos': TOKENS['ORGANISMOS'], 'huevos': TOKENS['HUEVOS'],
    'procesos': TOKENS['PROCESOS'], 'comportamientos': TOKENS['COMPORTAMIENTOS'], 
    'entrada': TOKENS['ENTRADA'], 'nacimiento': TOKENS['NACIMIENTO'],
    'plancton': TOKENS['PLANCTON'], 'delfin': TOKENS['DELFIN'], 'pulpo': TOKENS['PULPO'], 
    'cabeza': TOKENS['CABEZA'], 'tentaculo': TOKENS['TENTACULO'], 'tortuga': TOKENS['TORTUGA'], 
    'dodo': TOKENS['DODO'], 'perro': TOKENS['PERRO'], 'liebre': TOKENS['LIEBRE'],
    'tiburon': TOKENS['TIBURON'], 'sangre': TOKENS['SANGRE'], 'cortejo': TOKENS['CORTEJO'], 
    'atrae': TOKENS['ATRAE'], 'repele': TOKENS['REPELE'], 'loro': TOKENS['LORO'], 'mudo': TOKENS['MUDO'], 
    'migrar': TOKENS['MIGRAR'], 'desde': TOKENS['DESDE'], 'hasta': TOKENS['HASTA'], 'paso': TOKENS['PASO'], 
    'ruta': TOKENS['RUTA'], 'entrenar': TOKENS['ENTRENAR'], 'ritual': TOKENS['RITUAL'], 
    'canguro': TOKENS['CANGURO'], 'bolsa': TOKENS['BOLSA'], 'instruccion': TOKENS['INSTRUCCION'],
    
    'oveja': TOKENS['OVEJA'], 'huella': TOKENS['HUELLA'], 'serpiente': TOKENS['SERPIENTE'], 
    'gato': TOKENS['GATO'], 'colmena': TOKENS['COLMENA'], 'paloma': TOKENS['PALOMA'],
    'medusa': TOKENS['MEDUSA'], 'corral': TOKENS['CORRAL'], 'quebrantahuesos': TOKENS['QUEBRANTAHUESOS'], 
    'quimera': TOKENS['QUIMERA'], 'fosil': TOKENS['FOSIL'], 'cripsis': TOKENS['CRIPSIS'], 
    'habita': TOKENS['HABITA'], 'adopta': TOKENS['ADOPTA'], 'peligro': TOKENS['PELIGRO'],
    
    'camaleon': TOKENS['CAMALEON'], 'ballena': TOKENS['BALLENA'], 'machetear': TOKENS['MACHETEAR'], 
    'trozo': TOKENS['TROZO'], 'acechar': TOKENS['ACECHAR'], 'abeja': TOKENS['ABEJA'], 
    'aguijon': TOKENS['AGUIJON'], 'enjambre': TOKENS['ENJAMBRE'], 'miel': TOKENS['MIEL'], 
    'familia': TOKENS['FAMILIA'], 'presa': TOKENS['PRESA'], 'depredador': TOKENS['DEPREDADOR'], 
    'escamas': TOKENS['ESCAMAS'], 'enroscar': TOKENS['ENROSCAR'], 
    'mudar': TOKENS['MUDAR'], 'piel': TOKENS['PIEL'], 'clon': TOKENS['CLON'], 'acariciar': TOKENS['ACARICIAR'],
    'amarrar': TOKENS['AMARRAR'], 'ligo': TOKENS['LIGO'], 'aletear': TOKENS['ALETEAR'], 'nido': TOKENS['NIDO'],
    
    'boa': TOKENS['BOA'], 'can': TOKENS['CAN'], 'emu': TOKENS['EMU'], 'gnu': TOKENS['GNU'], 'yak': TOKENS['YAK'],
    'foca': TOKENS['FOCA'], 'mero': TOKENS['MERO'], 'orca': TOKENS['ORCA'], 'raya': TOKENS['RAYA'],
    
    'sim': TOKENS['SIM'], 'mut': TOKENS['MUT'], 'dep': TOKENS['DEP'], 'com': TOKENS['COM'],
    'hibrido': TOKENS['HIBRIDO'], 'presaclon': TOKENS['PRESACLON'], 'depredadorclon': TOKENS['DEPREDADORCLON'], 
    'aterrizar': TOKENS['ATERRIZAR'], 'pluma': TOKENS['PLUMA'], 'capturar': TOKENS['CAPTURAR'], 
    'reprender': TOKENS['REPRENDER'], 'renacer': TOKENS['RENACER'], 'transformar': TOKENS['TRANSFORMAR'], 
    
    'conejo': TOKENS['CONEJO'], 'oso come': TOKENS['OSO_COME'], 'panda come': TOKENS['PANDA_COME'],
    
    'esconejo?': TOKENS['ESCONEJO?'], 'eslobo?': TOKENS['ESLOBO?'], 'desolado?': TOKENS['DESOLADO?'], 
    'salvaje': TOKENS['SALVAJE'], 'docil': TOKENS['DOCIL']
}

class Token:
    def __init__(self, tipo, lexema, linea, columna):
        self.tipo = tipo
        self.lexema = lexema
        self.linea = linea
        self.columna = columna

class ScannerPasCat:
    def __init__(self):
        self.codigo = ""
        self.pos = 0
        self.linea = 1
        self.columna = 1
        self.token_guardado = None
        self.dentro_coleccion = False
        self.proximo_es_id_atributo = False
        self.estadisticas = {
            'lineas': 0, 'caracteres': 0, 'errores': 0,
            'com_linea': 0, 'com_bloque': 0, 'familias': {}
        }

    def inicializar_scanner(self, ruta_archivo):
        try:
            with open(ruta_archivo, 'r', encoding='utf-8', errors='ignore') as f:
                self.codigo = f.read()
                self.estadisticas['caracteres'] = len(self.codigo)
        except FileNotFoundError:
            print(f"Error fatal: No se pudo aletear (abrir) el archivo '{ruta_archivo}'.")
            sys.exit(1)

    def finalizar_scanner(self):
        self.estadisticas['lineas'] = self.linea

    def tome_token(self, token):
        self.token_guardado = token

    def avanzar(self):
        if self.pos < len(self.codigo):
            if self.codigo[self.pos] == '\n':
                self.linea += 1
                self.columna = 1
            else:
                self.columna += 1
            self.pos += 1

    def ver_actual(self):
        if self.pos < len(self.codigo):
            return self.codigo[self.pos]
        return None

    def ver_siguiente_no_espacio(self):
        i = self.pos
        while i < len(self.codigo) and self.codigo[i] in (' ', '\t', '\n', '\r'):
            i += 1
        if i < len(self.codigo):
            return self.codigo[i]
        return None

    def registrar_estadistica_familia(self, tipo):
        familia = "Desconocida"
        if 10 <= tipo <= 49: familia = "Fam 1: Identificadores y Literales"
        elif 100 <= tipo <= 199: familia = "Fam 2: Estructura y Control"
        elif 200 <= tipo <= 299: familia = "Fam 3: Tipos de Datos"
        elif 400 <= tipo <= 499: familia = "Fam 4: Operadores Especiales"
        elif 500 <= tipo <= 599: familia = "Fam 5: Funciones Intrínsecas"
        elif 300 <= tipo <= 399: familia = "Fam 6: Símbolos y Delimitadores"
        
        if familia != "Desconocida":
            self.estadisticas['familias'][familia] = self.estadisticas['familias'].get(familia, 0) + 1

    def deme_token(self):
        if self.token_guardado is not None:
            t = self.token_guardado
            self.token_guardado = None
            return t

        while self.ver_actual() in (' ', '\t', '\n', '\r'):
            self.avanzar()

        actual = self.ver_actual()
        if actual is None:
            return Token(TOKENS['EOF'], "", self.linea, self.columna)

        col_inicio = self.columna

        if self.proximo_es_id_atributo and not (actual.isalpha() or actual == '_'):
            self.proximo_es_id_atributo = False

        # Identificadores y Palabras Reservadas
        if actual.isalpha() or actual == '_':
            # Vistazo especial para literales compuestas del tipo creativo
            vistazo_oso = self.codigo[self.pos:self.pos+8].lower()
            vistazo_panda = self.codigo[self.pos:self.pos+10].lower()
            
            if vistazo_oso == "oso come":
                self.pos += 8; self.columna += 8
                t = Token(TOKENS['OSO_COME'], "oso come", self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t
            elif vistazo_panda == "panda come":
                self.pos += 10; self.columna += 10
                t = Token(TOKENS['PANDA_COME'], "panda come", self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t
            
            # Flujo normal de variables y reservas
            lexema = ""
            while self.ver_actual() is not None and (self.ver_actual().isalnum() or self.ver_actual() == '_' or self.ver_actual() == '?'):
                lexema += self.ver_actual()
                self.avanzar()
            
            lexema_lower = lexema.lower()
            if lexema_lower in ['v', 'm', 'vivo', 'muerto']:
                t = Token(TOKENS['LIT_GATO'], lexema, self.linea, col_inicio)
                if self.dentro_coleccion:
                    t.tipo = TOKENS['LIT_COLM']
                self.registrar_estadistica_familia(t.tipo)
                return t
            elif lexema_lower in PALABRAS_RESERVADAS:
                t = Token(PALABRAS_RESERVADAS[lexema_lower], lexema, self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t
            elif self.proximo_es_id_atributo:
                self.proximo_es_id_atributo = False
                t = Token(TOKENS['ID_ATRIBUTO'], lexema, self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t
            else:
                t = Token(TOKENS['ID'], lexema, self.linea, col_inicio)

            if self.pos < len(self.codigo) and self.codigo[self.pos] == '(':
                t.tipo = TOKENS['ID_FUNC']

            self.registrar_estadistica_familia(t.tipo)
            return t

        # Literales Oveja (Números)
        if actual.isdigit() or (actual == '-' and self.pos + 1 < len(self.codigo) and self.codigo[self.pos + 1].isdigit()):
            lexema = ""
            if actual == '-':
                lexema += '-'
                self.avanzar()
            while self.ver_actual() is not None and self.ver_actual().isdigit():
                lexema += self.ver_actual()
                self.avanzar()
            tipo_lit = TOKENS['LIT_COLM'] if self.dentro_coleccion else TOKENS['LIT_OVEJA']
            t = Token(tipo_lit, lexema, self.linea, col_inicio)
            self.registrar_estadistica_familia(t.tipo)
            return t

        # Literales Serpiente (String)
        if actual == '"':
            lexema = '"'
            self.avanzar()
            while self.ver_actual() is not None and self.ver_actual() not in ('"', '\n'):
                lexema += self.ver_actual()
                self.avanzar()
            if self.ver_actual() == '"':
                lexema += '"'
                self.avanzar()
                tipo_lit = TOKENS['LIT_COLM'] if self.dentro_coleccion else TOKENS['LIT_SERPIENTE']
                t = Token(tipo_lit, lexema, self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t
            else:
                self.estadisticas['errores'] += 1
                return Token(TOKENS['ERROR_LEXICO'], lexema, self.linea, col_inicio)

        # Literales Huella (Char)
        if actual == "'":
            lexema = "'"
            self.avanzar()
            while self.ver_actual() is not None and self.ver_actual() not in ("'", '\n'):
                lexema += self.ver_actual()
                self.avanzar()
            if self.ver_actual() == "'":
                lexema += "'"
                self.avanzar()
                tipo_lit = TOKENS['LIT_COLM'] if self.dentro_coleccion else TOKENS['LIT_HUELLA']
                t = Token(tipo_lit, lexema, self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t
            else:
                self.estadisticas['errores'] += 1
                return Token(TOKENS['ERROR_LEXICO'], lexema, self.linea, col_inicio)

        # Separadores de PasCat (~ y ~~)
        if actual == '~':
            self.avanzar()
            if self.ver_actual() == '~':
                self.avanzar()
                t = Token(TOKENS['SEP_SECCION'], "~~", self.linea, col_inicio)
            else:
                t = Token(TOKENS['SEP_INSTRUCCION'], "~", self.linea, col_inicio)
            self.registrar_estadistica_familia(t.tipo)
            return t

        # Asignación vs Comentarios
        if actual == '=':
            vistazo = self.codigo[self.pos:self.pos+5]
            if vistazo == "=^.^>":
                lexema = "=^.^>"
                self.pos += 5
                self.columna += 5
                profundidad = 1
                while self.pos < len(self.codigo) and profundidad > 0:
                    c_actual = self.codigo[self.pos:self.pos+5]
                    if c_actual == "=^.^>":
                        profundidad += 1; lexema += c_actual; self.pos += 5; self.columna += 5
                    elif c_actual == "<^.^=":
                        profundidad -= 1; lexema += c_actual; self.pos += 5; self.columna += 5
                    else:
                        if self.codigo[self.pos] == '\n': self.linea += 1; self.columna = 1
                        lexema += self.codigo[self.pos]
                        self.avanzar()
                self.estadisticas['com_bloque'] += 1
                return Token(TOKENS['COM_BLOQUE'], lexema, self.linea, col_inicio)

            # Comentario de línea
            elif vistazo == "=^.^=":
                lexema = "=^.^="
                self.pos += 5
                self.columna += 5
                while self.ver_actual() is not None and self.ver_actual() != '\n':
                    lexema += self.ver_actual()
                    self.avanzar()
                self.estadisticas['com_linea'] += 1
                return Token(TOKENS['COM_LINEA'], lexema, self.linea, col_inicio)
            else:
                self.avanzar()
                t = Token(TOKENS['ASIGNACION'], "=", self.linea, col_inicio)
                self.registrar_estadistica_familia(t.tipo)
                return t

        # Operadores Compuestos y Relacionales (<- , ><> , < , >)
        if actual == '<':
            self.avanzar()
            if self.ver_actual() == '-':
                self.avanzar()
                t = Token(TOKENS['DECLARACION'], "<-", self.linea, col_inicio)
            else:
                t = Token(TOKENS['MENOR_QUE'], "<", self.linea, col_inicio)
            self.registrar_estadistica_familia(t.tipo)
            return t

        if actual == '>':
            vistazo = self.codigo[self.pos:self.pos+3]
            # Validamos si es paso por referencia (><>)
            if vistazo == "><>":
                self.pos += 3
                self.columna += 3
                t = Token(TOKENS['REF_PARAM'], "><>", self.linea, col_inicio)
            # Validamos si es doble mayor que (>>)
            elif vistazo[:2] == ">>":
                self.pos += 2
                self.columna += 2
                t = Token(TOKENS['DESP_DER'], ">>", self.linea, col_inicio)
            else:
                self.avanzar()
                t = Token(TOKENS['MAYOR_QUE'], ">", self.linea, col_inicio)
            self.registrar_estadistica_familia(t.tipo)
            return t

        # Símbolos compuestos y simples directos
        if actual == '{':
            self.avanzar()
            if self.ver_actual() == '[':
                self.avanzar()
                t = Token(TOKENS['LLAVE_ABRE'], '{[', self.linea, col_inicio)
            elif self.ver_actual() == '@':
                self.avanzar()
                t = Token(TOKENS['LLAVE_ABRE'], '{@', self.linea, col_inicio)
            else:
                t = Token(TOKENS['LLAVE_ABRE'], '{', self.linea, col_inicio)
            self.dentro_coleccion = True
            self.registrar_estadistica_familia(t.tipo)
            return t

        if actual == '}':
            self.avanzar()
            t = Token(TOKENS['LLAVE_CIERRA'], '}', self.linea, col_inicio)
            self.dentro_coleccion = False
            self.registrar_estadistica_familia(t.tipo)
            return t

        if actual == ']':
            self.avanzar()
            if self.ver_actual() == '}':
                self.avanzar()
                t = Token(TOKENS['COR_CIERRA'], ']}', self.linea, col_inicio)
            else:
                t = Token(TOKENS['COR_CIERRA'], ']', self.linea, col_inicio)
            self.dentro_coleccion = False
            self.registrar_estadistica_familia(t.tipo)
            return t

        if actual == '@':
            self.avanzar()
            if self.ver_actual() == '}':
                self.avanzar()
                self.dentro_coleccion = False
                t = Token(TOKENS['ACCESO_REG'], '@}', self.linea, col_inicio)
            else:
                self.proximo_es_id_atributo = True
                t = Token(TOKENS['ACCESO_REG'], '@', self.linea, col_inicio)
            self.registrar_estadistica_familia(t.tipo)
            return t

        # Símbolos simples directos
        simbolos_simples = {
            '(': TOKENS['PAR_ABRE'], ')': TOKENS['PAR_CIERRA'], 
            ',': TOKENS['COMA'], ':': TOKENS['DOS_PUNTOS'],
            '$': TOKENS['DOLAR'], '[': TOKENS['COR_ABRE']
        }
        if actual in simbolos_simples:
            self.avanzar()
            t = Token(simbolos_simples[actual], actual, self.linea, col_inicio)
            self.registrar_estadistica_familia(t.tipo)
            return t
        
        # Si llegamos aquí, es un carácter no reconocido
        lexema_invalido = self.ver_actual()
        self.avanzar()
        self.estadisticas['errores'] += 1
        return Token(TOKENS['ERROR_LEXICO'], str(lexema_invalido), self.linea, col_inicio)

# ==========================================
# GENERADOR DE HTML
# ==========================================
def obtener_color_ladrillo(tipo_token):
    if 10 <= tipo_token <= 49: return "#28a745" # Fam 1: Verde
    if 100 <= tipo_token <= 199: return "#007bff" # Fam 2: Azul
    if 200 <= tipo_token <= 299: return "#6f42c1" # Fam 3: Morado
    if 400 <= tipo_token <= 499: return "#fd7e14" # Fam 4: Naranja
    if 500 <= tipo_token <= 599: return "#20c997" # Fam 5: Turquesa
    if 300 <= tipo_token <= 399: return "#343a40" # Fam 6: Gris Oscuro
    if tipo_token == 900 or tipo_token == 901: return "#e2e3e5; color: #6c757d" # Comentarios
    if tipo_token == 999: return "#dc3545" # Errores: Rojo
    return "#000000"

def generar_muro_html(tokens, estadisticas):
    html_content = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Muro de Ladrillos - PasCat</title>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px; }}
        .contenedor-muro {{ 
            display: flex; flex-direction: column; gap: 6px; margin-bottom: 30px; 
            background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }}
        .linea-muro {{ 
            display: flex; flex-wrap: wrap; gap: 5px; align-items: center; min-height: 32px; 
        }}
        .num-linea {{ 
            width: 40px; color: #adb5bd; font-family: monospace; text-align: right; 
            margin-right: 15px; user-select: none; font-size: 14px; border-right: 2px solid #e9ecef; padding-right: 10px;
        }}
        .ladrillo {{
            padding: 6px 12px; border-radius: 4px; color: white;
            font-weight: bold; box-shadow: 1px 1px 2px rgba(0,0,0,0.2);
            font-family: monospace; border: 1px solid rgba(0,0,0,0.1);
            font-size: 14px; white-space: pre-wrap;
        }}
        .stats {{ background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }}
        .lista-familias {{ list-style-type: none; padding-left: 0; }} /* Quita los puntos de la lista */
        h1, h2, h3 {{ color: #343a40; }}
    </style>
</head>
<body>
    <h1>Muro de Ladrillos Léxico</h1>
    <div class="contenedor-muro">
"""
    # Lógica para imprimir por líneas
    linea_actual = 1
    html_content += f'        <div class="linea-muro"><div class="num-linea">{linea_actual}</div>\n'
    
    for t in tokens:
        while linea_actual < t.linea:
            html_content += '        </div>\n'
            linea_actual += 1
            html_content += f'        <div class="linea-muro"><div class="num-linea">{linea_actual}</div>\n'
            
        color = obtener_color_ladrillo(t.tipo)
        lexema_seguro = html.escape(t.lexema).replace('\n', '&#10;')
        
        html_content += f'            <div class="ladrillo" style="background-color: {color};" title="Línea {t.linea}, Col {t.columna} (ID: {t.tipo})">{lexema_seguro}</div>\n'

    html_content += """        </div>
    </div>
    <div class="stats">
        <h2>Estadísticas de Compilación</h2>
        <ul>
"""
    if estadisticas['caracteres'] > 0: html_content += f"<li style='margin-bottom: 5px;'><strong>Caracteres leídos:</strong> {estadisticas['caracteres']}</li>\n"
    if estadisticas['lineas'] > 0: html_content += f"<li style='margin-bottom: 5px;'><strong>Líneas procesadas:</strong> {estadisticas['lineas']}</li>\n"
    if estadisticas['com_linea'] > 0: html_content += f"<li style='margin-bottom: 5px;'><strong>Comentarios de línea:</strong> {estadisticas['com_linea']}</li>\n"
    if estadisticas['com_bloque'] > 0: html_content += f"<li style='margin-bottom: 5px;'><strong>Comentarios de bloque:</strong> {estadisticas['com_bloque']}</li>\n"
    if estadisticas['errores'] > 0: html_content += f"<li style='color: #dc3545; font-weight: bold; margin-bottom: 5px;'>Errores léxicos recuperados: {estadisticas['errores']}</li>\n"
    
    html_content += "        </ul>\n        <h3>Familias Encontradas:</h3>\n        <ul class=\"lista-familias\">\n"
    
    # Diccionario para enlazar el texto de la familia con su color
    colores_familias = {
        "Fam 1: Identificadores y Literales": "#28a745",
        "Fam 2: Estructura y Control": "#007bff",
        "Fam 3: Tipos de Datos": "#6f42c1",
        "Fam 4: Operadores Especiales": "#fd7e14",
        "Fam 5: Funciones Intrínsecas": "#20c997",
        "Fam 6: Símbolos y Delimitadores": "#343a40"
    }

    # Imprimir cada familia con su respectivo cuadro de color
    for fam, cant in estadisticas['familias'].items():
        color_fam = colores_familias.get(fam, "#000000")
        html_content += f'            <li style="margin-bottom: 8px; display: flex; align-items: center;">\n'
        html_content += f'                <span style="display: inline-block; width: 16px; height: 16px; background-color: {color_fam}; margin-right: 10px; border-radius: 4px; box-shadow: 1px 1px 2px rgba(0,0,0,0.2);"></span>\n'
        html_content += f'                <strong>{fam}:</strong> &nbsp;{cant} tokens\n'
        html_content += f'            </li>\n'
    
    html_content += """        </ul>
    </div>
</body>
</html>"""

    with open("muro.html", "w", encoding="utf-8") as f:
        f.write(html_content)
    print("¡Amurallamiento exitoso! Archivo 'muro.html' generado.")

def main():
    if len(sys.argv) < 2:
        print("Uso: python scanner.py <archivo.cat>")
        sys.exit(1)

    ruta_archivo = sys.argv[1]
    scanner = ScannerPasCat()
    scanner.inicializar_scanner(ruta_archivo)

    tokens_encontrados = []
    
    while True:
        t = scanner.deme_token()
        if t.tipo == TOKENS['EOF']:
            break
        tokens_encontrados.append(t)

    scanner.finalizar_scanner()
    generar_muro_html(tokens_encontrados, scanner.estadisticas)

if __name__ == "__main__":
    main()