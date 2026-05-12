from scanner import ScannerPasCat 
from tabla_parsing import TABLA_PARSING 
from parser import ParserPasCat 

def compilar_archivo(ruta_archivo):
    print(f"\nIniciando compilacion de: {ruta_archivo}")
    
    mi_scanner = ScannerPasCat()
    
    try:
        with open(ruta_archivo, "r", encoding="utf-8") as f:
            mi_scanner.codigo = f.read()
    except FileNotFoundError:
        print(f"Error: No se pudo encontrar el archivo {ruta_archivo}")
        return

    mi_parser = ParserPasCat(mi_scanner, TABLA_PARSING)
    mi_parser.analizar()
    
    print("Revisa el archivo 'reporte_sintactico.log' para ver el detalle.")

if __name__ == '__main__':
    archivo_prueba = "pruebas/32-declaracion_multiple-00.cat" 
    compilar_archivo(archivo_prueba)