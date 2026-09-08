# Betriebshandbuch 04: Notfall-Aussetzung der Emission

## Zielsetzung

Die Erstellung neuer **CBDT (Central Bank Digital Token)** wird ausgesetzt, wenn die monetäre Integrität durch unbefugte Emission, Abweichungen bei der Angebotsabstimmung, kompromittierte Signaturschlüssel, Smart-Contract-Schwachstellen oder einen anderen schwerwiegenden Vorfall gefährdet ist.

Dieses Betriebshandbuch beschreibt den generischen CentralBank-Ablauf. Die zuständige Genehmigungs- und Notfallinstanz wird durch das jeweilige Bereitstellungsprofil und Governance-Modell festgelegt.

## Vorbedingungen

1. Ein bestätigter oder glaubwürdiger Grund für die Aussetzung der Emission.
2. Authentifizierter Zugriff auf die institutionelle Steuerungsebene.
3. Die für den betroffenen Vertrag oder Controller erforderliche Notfall- oder Emissionsberechtigung.
4. Eine Vorfalls-/Fallreferenz und dokumentierte Genehmigung.

## Ausführungsschritte

### 1. Umfang der Aussetzung bestimmen

Prüfen Sie, ob nur die Mint-Funktion des `MintBurnControllerV2`, der aktuelle `DigitalToken` oder aufgrund eines Integritätsproblems das gesamte Transfersystem pausiert werden muss. Verwenden Sie die engste Kontrolle, die den Vorfall sicher eindämmt.

### 2. Genehmigte Pause ausführen

Für Bereitstellungen mit dem aktuellen systemweiten Gateway-Endpunkt:

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/pause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

Je nach Bereitstellung können zusätzlich institutionelles mTLS und Request-Signaturen erforderlich sein.

Wenn der modulare Mint/Burn-Controller eingesetzt wird, sollte bei einem reinen Emissionsvorfall dessen separate Mint-Pause bevorzugt werden, sofern Transfers und Rücknahmen sicher fortgeführt werden können.

### 3. On-Chain-Status verifizieren

Bestätigen Sie den relevanten Pause-Status direkt am bereitgestellten Vertrag/Controller und erfassen Sie Transaktionsbeleg und Blockhöhe.

### 4. Teilnehmer benachrichtigen

Die Mitteilung muss mindestens enthalten: ausgesetzte Funktion, Wirksamkeitszeitpunkt, erwartetes Teilnehmerverhalten, Verfügbarkeit von Transfers/Rücknahmen, Vorfallsreferenz und nächsten Kommunikationskanal.

Behaupten Sie keine automatische Benachrichtigung, wenn die konkrete Bereitstellung diesen Mechanismus nicht tatsächlich implementiert und verifiziert.

## Abstimmung während der Aussetzung

Die Reconciliation und Beweissicherung muss fortgesetzt werden. Erfassen Sie insbesondere das letzte bekannte gültige Gesamtangebot, autorisierte Emissions-/Rücknahmevorgänge, unbekannte Transaktions- oder Operations-Hashes sowie relevante Signer-, KMS- und Knotendaten.

Unerklärte Angebotsabweichungen dürfen nicht als normale Buchungskorrektur behandelt werden.

## Sichere Wiederaufnahme

1. Ursache ausreichend analysieren oder eindämmen.
2. Gesamtangebot und alle Emissions-/Rücknahmevorgänge des Vorfallszeitraums abstimmen.
3. Integrität von Signern und Berechtigungen prüfen; kompromittierte Berechtigungen vor Wiederaufnahme rotieren.
4. Genehmigung gemäß Bereitstellungsprofil einholen.
5. Nur die tatsächlich ausgesetzten Kontrollen wieder freigeben.
6. Falls angemessen, eine kleine autorisierte Validierungsoperation durchführen.
7. Erneut exakte Reconciliation bestätigen.

Für eine systemweite Wiederfreigabe:

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/unpause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

## Erzeugte Audit-Artefakte

Erwartete Nachweise umfassen Pause-/Unpause-Transaktionsbelege und Ereignisse, Vorfalls- und Genehmigungsreferenz, handelnde institutionelle Identität, Angebotsabstimmung, Nachweis der Signer-/Berechtigungsintegrität sowie Ergebnisse der Wiederanlaufvalidierung.

## Eurosystem-Referenzprofil

Eine Eurosystem-orientierte Bereitstellung kann die Genehmigungskette auf EZB/NZB- oder delegierte Notfallinstanzen abbilden. Diese Zuordnung ist profilspezifisch und stellt keine durch die CentralBank-Software selbst verliehene Zuständigkeit dar.

CentralBank und CBDT werden weder von der Europäischen Zentralbank, dem Eurosystem noch einer nationalen Zentralbank herausgegeben, unterstützt, gesponsert, genehmigt oder betrieben.
