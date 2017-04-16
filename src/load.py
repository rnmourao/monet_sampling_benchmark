# This Python file uses the following encoding: utf-8
import csv
import codecs
from os import listdir
from os.path import isfile, join

# get list of csv files
mypath = '/media/mourao/BACKUP/bolsa_familia/'
files = [f for f in listdir(mypath) if isfile(join(mypath, f)) and f[-3:] == 'csv']

# create a new csv with less columns from list of csv files
reduced = open(mypath + 'reduced.csv', 'w')
fieldnames = ['year', 'month', 'state', 'municipality', 'payee', 'value']
writer = csv.DictWriter(reduced, fieldnames=fieldnames)

writer.writeheader()
for file in files:
    print(file)
    csvfile = codecs.open(mypath + file, 'r', 'iso-8859-1')
    reader = csv.DictReader(csvfile, delimiter='\t', quotechar=' ')
    for row in reader:
        year = file[:4]
        month = file[4:6]
        state = row.get('UF', '')
        municipality = row.get('Código SIAFI Município', '')
        payee = row.get('NIS Favorecido', '')
        value = row.get('Valor Parcela', '')
        writer.writerow({'year': year, 'month': month, 'state': state, 'municipality': municipality, 'payee': payee, 'value': value})
    csvfile.close()

reduced.close()
