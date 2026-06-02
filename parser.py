class ParserPasCat:
    def __init__(self, scanner, tabla_parsing, analizador_contextual=None):
        self.scanner = scanner
        self.tabla_parsing = tabla_parsing
        self.analizador = analizador_contextual
        self.pila = []
        self.token_actual = None
        
        self.tokens_sincronizacion = ['~', '~~', 'plancton', 'delfin', 'Muerte', 'Reino', 'Nacimiento', 'EOF']
        
        self.archivo_log = open("reporte_sintactico.log", "w", encoding="utf-8")
        self.archivo_log.write("=== Inicio del Análisis Sintáctico ===\n\n")
        
        self.terminales_gikgram = {t.lower(): t for nt, t in self.tabla_parsing.keys()}

    def registrar_error(self, mensaje):
        lexema = self.token_actual.lexema if self.token_actual else "EOF"
        linea = self.token_actual.linea if self.token_actual else "Fin de archivo"
        error_str = f"[!] Error Sintactico [Linea {linea}]: {mensaje} (Token actual: '{lexema}')\n"
        print(error_str.strip())
        self.archivo_log.write(error_str)

    def es_terminal(self, simbolo):
        if isinstance(simbolo, int):
            return False
        return not (simbolo.startswith('<') and simbolo.endswith('>'))

    def obtener_nombre(self):
            if self.token_actual is None: return 'EOF'
            
            lexema_str = str(self.token_actual.lexema).strip()
            lexema_lower = lexema_str.lower()
            tipo = self.token_actual.tipo

            if lexema_lower in ('eof',) or (lexema_str == '' and tipo in (0, -1, 'EOF')): 
                return 'EOF'

            if lexema_lower in self.terminales_gikgram:
                return self.terminales_gikgram[lexema_lower]

            if tipo == 10:
                if lexema_lower in ('muerto', 'vivo', 'minimo', 'bajo', 'medio', 'alto', 'maximo'):
                    return lexema_lower
                return 'Id'
            if tipo == 11: return 'Id_Func'
            if tipo == 12: return 'Id_Op_Aritmetico'
            if tipo == 13: return 'Id_Op_Caracter'
            if tipo == 14: return 'Id_Op_Logico'
            if tipo == 15: return 'Id_Op_Str'
            if tipo == 16: return 'Id_Op_Conj'
            if tipo == 17: return 'Id_Op_Com'
            if tipo == 18: return 'Id_Op_Creat'
            if tipo == 19: return 'Id-atributo'
            if tipo == 20: return 'lit-oveja'
            if tipo == 21: return 'lit-huella'
            if tipo == 22: return 'lit-serpiente'
            if tipo == 24: return 'lit-colm'

            return str(self.token_actual.lexema)

    def pedir_token(self):
        """Pide tokens al escáner ignorando comentarios y espacios vacíos"""
        while True:
            token = self.scanner.deme_token()
            if token is None: 
                return None
            
            lexema_str = str(token.lexema).strip()
            
            # 1. Ignorar comentarios de PasCat (=^.^=)
            if lexema_str.startswith('=^.^='):
                continue
                
            # 2. Ignorar tokens de error o espacios
            if token.tipo in [999]:
                continue
                
            # 3. Ignorar tokens vacíos (como saltos de línea \n) que NO sean el Fin de Archivo
            if lexema_str == '' and token.tipo not in [0, -1, 'EOF']: 
                continue
                
            # Si pasó los filtros, es un token útil para la gramática
            return token

    def recuperar_panico(self, cima):
        self.registrar_error(f"Estructura inesperada evaluando '{cima}'. Iniciando recuperacion...")
        
        while self.obtener_nombre() not in self.tokens_sincronizacion:
            if self.obtener_nombre() == 'EOF': 
                break
            self.token_actual = self.pedir_token()
            
        lexema = self.token_actual.lexema if self.token_actual else "EOF"
        linea = self.token_actual.linea if self.token_actual else "-"
        self.archivo_log.write(f"   -> Sincronizado en token '{lexema}' (Linea {linea}). Retomando analisis...\n")

    def analizar(self):
        self.pila.append('EOF')
        self.pila.append('<Titulo>')
        self.token_actual = self.pedir_token()

        while len(self.pila) > 0:
            cima = self.pila[-1]
            nombre_actual = self.obtener_nombre()

            if isinstance(cima, int):
                if self.analizador:
                    self.analizador.ejecutar(cima, self.token_actual)
                self.pila.pop()
                continue

            if cima == 'EOF':
                if nombre_actual == 'EOF':
                    exito = "[+] Analisis sintactico completado con exito!"
                    print(exito)
                    self.archivo_log.write("\n" + exito)
                else:
                    self.registrar_error("Se esperaba el fin de archivo, pero hay mas codigo.")
                break

            elif self.es_terminal(cima):
                coincide = (cima == nombre_actual or
                            (cima == 'Id' and nombre_actual == 'Id_Func') or
                            (cima == 'Id_Func' and nombre_actual == 'Id'))
                if coincide:
                    if self.analizador:
                        self.analizador.notificar_terminal(cima, self.token_actual)
                    self.pila.pop()
                    self.token_actual = self.pedir_token()
                else:
                    self.registrar_error(f"Se esperaba el terminal '{cima}'.")
                    self.pila.pop() 

            else:
                produccion = self.tabla_parsing.get((cima, nombre_actual))
                if produccion is not None:
                    self.pila.pop()
                    if produccion != ['epsilon']:
                        for simbolo in produccion:
                            self.pila.append(simbolo)
                else:
                    self.recuperar_panico(cima)
                    self.pila.pop()

        self.archivo_log.close()