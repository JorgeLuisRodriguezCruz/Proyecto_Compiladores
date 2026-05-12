class ParserPasCat:
    def __init__(self, scanner, tabla_parsing):
        self.scanner = scanner
        self.tabla_parsing = tabla_parsing
        self.pila = []
        self.token_actual = None
        
        self.tokens_sincronizacion = ['~', '~~', 'plancton', 'delfin', 'Muerte', 'EOF']
        
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
        return not (simbolo.startswith('<') and simbolo.endswith('>'))

    def obtener_nombre(self):
            if self.token_actual is None: return 'EOF'
            
            lexema_str = str(self.token_actual.lexema).strip()
            lexema_lower = lexema_str.lower()
            tipo = self.token_actual.tipo

            # Detectar el Fin de Archivo (EOF) de forma segura
            if lexema_lower == 'eof' or (lexema_str == '' and tipo in [0, -1, 'EOF']): 
                return 'EOF'

            # Clasificación de familias
            if tipo == 10: 
                if lexema_lower in ['muerto', 'vivo', 'minimo', 'bajo', 'medio', 'alto', 'maximo']:
                    return lexema_lower
                return 'Id'
            elif tipo == 20: return 'lit-oveja'
            elif tipo == 21: return 'lit-huella'
            elif tipo == 22: return 'lit-serpiente'
            
            if lexema_lower in self.terminales_gikgram:
                return self.terminales_gikgram[lexema_lower]
                
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
            nombre_actual = self.obtener_nombre() # ¡Usamos el traductor!

            if cima == 'EOF':
                if nombre_actual == 'EOF':
                    exito = "[+] Analisis sintactico completado con exito!"
                    print(exito)
                    self.archivo_log.write("\n" + exito)
                else:
                    self.registrar_error("Se esperaba el fin de archivo, pero hay mas codigo.")
                break

            elif self.es_terminal(cima):
                if cima == nombre_actual:
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