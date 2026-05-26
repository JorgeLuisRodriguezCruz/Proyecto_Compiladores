from scanner import ScannerPasCat 
from tabla_parsing import TABLA_PARSING 
from parser import ParserPasCat 
from analizador_contextual import AnalizadorContextual

def compilar_archivo(ruta_archivo):
    print(f"\nIniciando compilacion de: {ruta_archivo}")
    
    mi_scanner = ScannerPasCat()
    
    try:
        with open(ruta_archivo, "r", encoding="utf-8") as f:
            mi_scanner.codigo = f.read()
    except FileNotFoundError:
        print(f"Error: No se pudo encontrar el archivo {ruta_archivo}")
        return

    mi_analizador = AnalizadorContextual()
    mi_parser = ParserPasCat(mi_scanner, TABLA_PARSING, mi_analizador)
    mi_parser.analizar()
    
    if mi_analizador.errores:
        print(f"\n[!] Compilacion con {len(mi_analizador.errores)} error(es) contextual(es).")
    else:
        print("\n[+] Analisis contextual completado sin errores.")
    print("Revisa el archivo 'reporte_sintactico.log' para ver el detalle.")

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        archivo_prueba = sys.argv[1]
    else:
        archivo_prueba = "Pruebas/22-gato-00.cat"
    compilar_archivo(archivo_prueba)