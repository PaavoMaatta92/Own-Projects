# -*- coding: UTF-8 -*-
import math
import cmath
def tulostus(tulostettava):
    """Tulostaa annetut ja lasketut arvot."""
    v = 0
    for i in tulostettava:
        v += 1
        print ("haara %d") % (v)
        for k in i:
            print (k)
    return "\n"
    
def laske_jannite(haaran_virta, komponentin_impedanssi):
    
    """Laskee haaran virran sekä komponentin impedanssin avulla jännitteet jokaisen komponentin yli ja palauttaa jännitteet listana.
        Virrat ja impedanssit on annettu funktiolle listoina."""
    
    jannitteet = []
    v = 0
    for i in komponentin_impedanssi:
        virta = haaran_virta[v]
        v += 1
        lista = []
        for k in i:
            jannite = osoitin_kertolasku(virta, muunna_osoitinmuotoon(k))
            lista.append(jannite)
        jannitteet.append(lista)
    return jannitteet

def laske_haarojen_virrat(virta, haaran_impedanssi, haarojen_lkm):
    
    """Laskee jokaisen haaran virran annetun kokonaisvirran sekä haaran kokonaisimpedanssin avulla.
        Palauttaa haarojen virrat listana"""
    
    haarojen_virrat = []
    for i in range(int(haarojen_lkm)):
        haarojen_virrat.append(osoitin_kertolasku(virta, osoitin_jakolasku((muunna_osoitinmuotoon((1/haaran_impedanssi[0][i]))),
                                                                           muunna_osoitinmuotoon((1/laske_rinnan(haaran_impedanssi[0]))))))
    return haarojen_virrat

def osoitin_kertolasku(luku1, luku2):
    
    """Laskee annettujen osoitinmuodossa olevien lukujen välisen kertolaskun"""
    
    r = luku1[0]*luku2[0]
    aste = luku1[1]+luku2[1]
    return (r, aste)

def osoitin_jakolasku(luku1, luku2):
    
    """Laskee annettujen osoitinmuodossa olevien lukujen välisen jakolaskun"""
    
    r = luku1[0]/luku2[0]
    aste = luku1[1]-(-1*luku2[1])
    return (r, aste)

def laske_kokonaisvirta(jannite, haaran_impedanssi):
    
    """Muuttaa jännitteen osoitinmuotton, jonka jälkeen laskee piirin kokonaisimpedanssin haarojen kokonaisimpedanssien avulla ja muuttaa sen osoitinmuotoon.
       Lopuksi laskee piirin kokonaisvirran annetun jännitteen sekä kokonaisimpedanssin avulla ja palauttaa sen osoitinmuodossa."""
    
    jannite_osoitinmuodossa = muunna_osoitinmuotoon(jannite)
    kokonais_impedanssi = muunna_osoitinmuotoon(laske_rinnan(haaran_impedanssi[0]))
    virta_osoitinmuodossa = osoitin_jakolasku(muunna_osoitinmuotoon(jannite), kokonais_impedanssi)
    return virta_osoitinmuodossa

def muunna_osoitinmuotoon(luku):

    """Muuttaa annetun luvun osoitinmuotoon"""
    
    luku1 = []
    luku1 = (cmath.polar(complex(luku)))
    aste = luku1[1]/((2*cmath.pi)/360)
    r = luku1[0]
    koord = (r, aste)
    return koord

def laske_sarja(impedanssit_lista):

    """Ottaa jokaisen haaran sarjassa olevat impedanssit listana ja laskee haaran kokonaisimpedanssin ja palauttaa sen listana,
        sekä kompleksi- että osoitinmuodossa"""
    
    haaran_impedanssi = []
    haara_osoitinmuodossa = []
    for i in impedanssit_lista:
        summa_reaali = 0
        summa_imaginaari = 0
        summa = 0
        for k in i:
            reaali = k.real
            imaginaari = k.imag
            if reaali == 0:
                summa_imaginaari += imaginaari
            elif imaginaari == 0:
                summa_reaali += reaali
            else:
                summa_reaali += reaali
                summa_imaginaari += imaginaari
        if summa_imaginaari == 0:
            summa = complex(summa_reaali, 0)
            haara_osoitinmuodossa.append(muunna_osoitinmuotoon(summa))
            haaran_impedanssi.append(summa)
        elif summa_reaali == 0:
            summa = complex(0, summa_imaginaari)
            haara_osoitinmuodossa.append(muunna_osoitinmuotoon(summa))
            haaran_impedanssi.append(summa)
        else:
            summa = complex(summa_reaali, summa_imaginaari)
            haara_osoitinmuodossa.append(muunna_osoitinmuotoon(summa))
            haaran_impedanssi.append(summa)
    return (haaran_impedanssi, haara_osoitinmuodossa)

def testaa_arvo(kysely):

    """Testaa annetun luvun kelvollisuuden"""
    
    while True:
        try:
            arvo = float(input(kysely))
            if arvo <= 0:
                print ("Epäkelpo arvo, yritä uudelleen.")
                continue
            else:
                return arvo
                break
        except ValueError:
            print ("Epäkelpo arvo, yritä uudelleen.")
            continue


def laske_rinnan(rinnan):

    """Ottaa vastaan impedanssit listana ja laskee niiden välisen rinnanimpedanssin ja palauttaa sen yhtenä arvona."""
    
    summa_reaali = 0
    summa_imaginaari = 0
    summa = 0
    for i in rinnan:
        reaali = i.real
        imaginaari = i.imag
        if reaali == 0:
            kaanteisluku_imaginaari = 1/imaginaari
            summa_imaginaari = summa_imaginaari + kaanteisluku_imaginaari
        elif imaginaari == 0:
            kaanteisluku_reaali = 1/reaali
            summa_reaali = summa_reaali + kaanteisluku_reaali
        else:
            kaanteisluku_reaali = 1/reaali
            kaanteisluku_imaginaari = 1/imaginaari
            summa_reaali = summa_reaali + kaanteisluku_reaali
            summa_imaginaari = summa_imaginaari + kaanteisluku_imaginaari
    if summa_imaginaari == 0:
        summa = complex(summa_reaali, 0)
    elif summa_reaali == 0:
        summa = complex(0, summa_imaginaari)
    else:
        summa = complex(summa_reaali, summa_imaginaari)
    rinnan_resistanssi = 1/ summa
    return rinnan_resistanssi



def rinnan_komponentit(taajuus):

    """Funktio kysyy haarassa olevien rinnankomponenttien tyypin sekä arvon ja palauttaa rinnankomponentit listana"""

    komponenttien_impedanssit = []
    maara = 0
    while True:
        komponentin_tyyppi = str(raw_input("Syötä rinnankytkennän komponentit (R L C). E:llä siirryt eteenpäin. "))
        if komponentin_tyyppi == "E" or komponentin_tyyppi == "e":
            return (komponenttien_impedanssit, maara)
            break
        elif not komponentin_tyyppi in ("R", "r", "C", "c", "L", "l"):
            print ("Epäkelpo arvo, yritä uudelleen.")
            continue
        else:
            komponentin_impedanssi = komponentit(komponentin_tyyppi, taajuus)
            komponenttien_impedanssit.append(komponentin_impedanssi[0])
            maara += 1
            continue

        
def komponentit(komponentin_tyyppi, taajuus):

    """Tarkistaa minkä tyyppisen komponentin käyttäjä on antanut haaraan ja kysyy sen arvon, sekä laskee komponenttien impedanssit
        ja paluttaa sekä impedanssit että komponenttien arvot. Tarkistaa myös jos käyttäjä haluaa syöttää haaraan rinnankomponentteja,
        jolloin siirtyy rinnan_komponentit funktioon ja laskee sen paluuarvon(lista) rinnanimpedanssin."""
    
    pi = cmath.pi
    komponenttien_arvot = []
    if komponentin_tyyppi == "R" or komponentin_tyyppi == "r":
        komponentin_arvo = testaa_arvo("Anna komponentin arvo: ")
        komponenttien_arvot.append(komponentin_arvo)
        impedanssi = komponentin_arvo
        impedanssi_1 = impedanssi
        return (impedanssi_1, komponenttien_arvot, impedanssi)
    elif komponentin_tyyppi == "L" or komponentin_tyyppi == "l":
        komponentin_arvo = testaa_arvo("Anna komponentin arvo: ")
        komponenttien_arvot.append(komponentin_arvo)
        impedanssi = ((2*pi) * taajuus * komponentin_arvo)*1j
        impedanssi_1 = impedanssi*-1
        return (impedanssi_1, komponenttien_arvot, impedanssi)
    elif komponentin_tyyppi == "C" or komponentin_tyyppi == "c":
        komponentin_arvo = testaa_arvo("Anna komponentin arvo: ")
        komponenttien_arvot.append(komponentin_arvo)
        impedanssi = 1/((2*pi) * taajuus * komponentin_arvo)*-1j
        impedanssi_1 = impedanssi*-1
        return (impedanssi_1, komponenttien_arvot, impedanssi)
    elif komponentin_tyyppi == "P" or komponentin_tyyppi == "p":
        rinnan_impedanssi = rinnan_komponentit(taajuus)
        if rinnan_impedanssi[1] == 0:
            return "T"
        else:
            rinnan_impedanssit = laske_rinnan(rinnan_impedanssi[0])
            komponenttien_arvot.append(rinnan_impedanssit)
            return (rinnan_impedanssit, komponenttien_arvot, rinnan_impedanssit)
    elif komponentin_tyyppi == "E" or komponentin_tyyppi == "e":
        return "E" 
    else:
        return 


while True:
    
    """ Pääkoodi. Kysyy jännitten, taajuuden, haarojen lukumäärän sekä komponenttien tyypit."""
    
    jannite = testaa_arvo("Anna lähteen jännite: ")
    taajuus = testaa_arvo("Anna lähteen taajuus: ")
    haarojen_lkm = testaa_arvo("Montako haaraa tehonlähteestä lähtee: ")
    komponentin_resistanssi = []
    komponentin_arvo = []
    silmukka = 0
    for i in range(int(haarojen_lkm)):
        print ("Syötä haaran %d komponentit. E:llä siirryt eteenpäin.P:llä voit syöttää haaraan komponentteja rinnakkain" %(i+1))
        lista = []
        lista1 = []
        maara = 0
        while True:
            try:
                komponentin_tyyppi = str(input("Anna haaraan %d sarjaan kytketyn komponentin tyyppi (R L C): " %(i+1)))
                komponentin_impedanssi = komponentit(komponentin_tyyppi, taajuus)
                if not komponentin_tyyppi:
                    print ("Epäkelpo arvo, yritä uudelleen.")
                    continue
                elif komponentin_impedanssi == "E" and maara == 0:
                    print ("Haaraan pitää syöttää vähintään yksi komponentti!")
                    continue
                elif komponentin_impedanssi == "E":
                    komponentin_resistanssi.append(lista)
                    komponentin_arvo.append(lista1)
                    break
                elif komponentin_impedanssi == "T":
                    continue
                elif not komponentin_tyyppi in ("R", "r", "C", "c", "L", "l", "P", "p"):
                    print ("Epäkelpo arvo, yritä uudelleen.")
                    continue
                else:
                    lista.append(komponentin_impedanssi[2])
                    lista1.append(komponentin_impedanssi[1])
                    silmukka += 1
                    maara += 1
                    continue
            except ValueError:
                print ("Epäkelpo arvo, yritä uudelleen.")
                continue
    haaran_impedanssi = laske_sarja(komponentin_resistanssi)
    virta = laske_kokonaisvirta(jannite, haaran_impedanssi)
    virrat = laske_haarojen_virrat(virta, haaran_impedanssi, haarojen_lkm)
    jannitteet = laske_jannite(virrat, komponentin_resistanssi)
    print ("\nkomponenttien arvot")
    print (tulostus(komponentin_arvo))
    print ("\nImpedanssit (ohmeina)")
    print (tulostus(komponentin_resistanssi))
    print ("\nJännitteet (voltit, vaihe)")
    print (tulostus(jannitteet))
    print ("\nHaarojen virrat (ampeerit, vaihe)")
    print (tulostus(virrat))
    alusta = input("PÃ¤Ã¤stiin ohjelman loppuun, aloitetaanko alusta (K/E)?")
    if alusta == "k" or alusta == "K":
        continue
    else:
        break
