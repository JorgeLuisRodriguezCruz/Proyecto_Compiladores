ACCIONES_SEMANTICAS = {
    231: 'Crea_TS_general',
    232: 'Id_program_coincide',
    233: 'Elimina_TS_general',
    234: 'ChkNoExist',
    235: 'ChkExistDato',
    236: 'ChkLiteralCorrecto',
    237: 'Crea_TS_local',
    238: 'Elimina_TS_local',
    239: 'ChkNoExistParam',
    240: 'ChkExist',
    241: 'ExpValidaIf',
    242: 'ChkCabezaUnica',
    243: 'ChkValorCorrecto',
    244: 'ChkValidaWhile',
    245: 'ChkValidaRepeat',
    246: 'ChkOpValida',
    247: 'ChkEstoyEnFunc',
    248: 'ChkTipoCorrecto',
}

TOKENS_POR_NOMBRE = {v: k for k, v in {
    'LIT_OVEJA': 20, 'LIT_HUELLA': 21, 'LIT_SERPIENTE': 22,
    'LIT_GATO': 23, 'LIT_COLM': 24,
}.items()}

class AnalizadorContextual:
    def __init__(self):
        self.ts_global = {}
        self.ts_local = None
        self.nombre_programa = None
        self._primer_id_guardado = False
        self.en_funcion = False
        self.errores = []

    def notificar_terminal(self, nombre_terminal, token):
        if nombre_terminal == 'Id' and not self._primer_id_guardado:
            self.nombre_programa = token.lexema
            self._primer_id_guardado = True

    def ejecutar(self, codigo, token_actual):
        metodo = ACCIONES_SEMANTICAS.get(codigo)
        if metodo:
            getattr(self, metodo)(token_actual)

    def Crea_TS_general(self, token):
        self.ts_global = {}
        self.archivo_log("Creada tabla de simbolos global")

    def Id_program_coincide(self, token):
        nombre_actual = token.lexema if token else ''
        if nombre_actual.lower() != self.nombre_programa.lower():
            msg = f"El nombre del programa '{nombre_actual}' no coincide con el declarado '{self.nombre_programa}'"
            self.error(msg, token)

    def Elimina_TS_general(self, token):
        self.ts_global = {}
        self.archivo_log("Eliminada tabla de simbolos global")

    def ChkNoExist(self, token):
        nombre = token.lexema if token else ''
        duplicado = (nombre in self.ts_global) or (self.ts_local is not None and nombre in self.ts_local)
        if duplicado:
            self.error(f"El identificador '{nombre}' ya existe en el ambito actual", token)
            return
        ts = self.ts_local if self.ts_local is not None else self.ts_global
        ts[nombre] = {'tipo': None}

    def ChkExistDato(self, token):
        nombre = token.lexema if token else ''
        existe = (nombre in self.ts_global) or (self.ts_local is not None and nombre in self.ts_local)
        if not existe:
            self.error(f"El identificador '{nombre}' no existe", token)

    def ChkLiteralCorrecto(self, token):
        pass

    def Crea_TS_local(self, token):
        self.ts_local = {}
        self.en_funcion = True
        self.archivo_log("Creada tabla de simbolos local")

    def Elimina_TS_local(self, token):
        self.ts_local = None
        self.en_funcion = False
        self.archivo_log("Eliminada tabla de simbolos local")

    def ChkNoExistParam(self, token):
        nombre = token.lexema if token else ''
        if self.ts_local is not None and nombre in self.ts_local:
            self.error(f"El parametro '{nombre}' ya existe en la funcion", token)
            return
        if self.ts_local is not None:
            self.ts_local[nombre] = {'tipo': None}

    def ChkExist(self, token):
        nombre = token.lexema if token else ''
        existe = (nombre in self.ts_global) or (self.ts_local is not None and nombre in self.ts_local)
        if not existe:
            self.error(f"El identificador '{nombre}' no esta declarado", token)

    def ExpValidaIf(self, token):
        pass

    def ChkCabezaUnica(self, token):
        pass

    def ChkValorCorrecto(self, token):
        pass

    def ChkValidaWhile(self, token):
        pass

    def ChkValidaRepeat(self, token):
        pass

    def ChkOpValida(self, token):
        pass

    def ChkEstoyEnFunc(self, token):
        if not self.en_funcion:
            self.error("Instruccion solo permitida dentro de una funcion", token)

    def ChkTipoCorrecto(self, token):
        pass

    def error(self, mensaje, token):
        linea = token.linea if token else 0
        lexema = token.lexema if token else ''
        error_str = f"[!] Error Contextual [Linea {linea}]: {mensaje} (Token: '{lexema}')"
        print(error_str)
        self.errores.append(error_str)

    def archivo_log(self, mensaje):
        print(f"  [Contextual] {mensaje}")
