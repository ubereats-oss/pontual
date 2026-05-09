# Pontual

App Flutter para bater ponto por proximidade GPS.

## Fluxo principal

- Login e cadastro por e-mail/senha via Firebase Auth.
- Usuario cria um local de ponto ou entra em um local existente por codigo.
- Admin define o raio permitido em metros ao criar o local.
- Chegada e saida so sao registradas dentro do raio, com GPS recente, preciso e sem sinal de localizacao simulada.
- Tentativas bloqueadas sao gravadas para auditoria.

## Matriz de decisao

| Decisao | Escolha | Motivo |
| --- | --- | --- |
| Autenticacao | Firebase Auth | Simples, seguro e igual ao padrao inicial do Meu Baba |
| Dados | Cloud Firestore | Tempo real para locais, membros e pontos |
| GPS | Geolocator | Entrega distancia, precisao, timestamp e `isMocked` |
| Anti fake GPS | Bloqueio por `isMocked`, precisao, idade do sinal e distancia | Melhor protecao possivel no app sem servidor de integridade |
| Entrada em local | Codigo de 6 caracteres | Facil para usuario nao tecnico |

## Prioridades

1. Confiabilidade do ponto.
2. Fluxo simples para usuario comum.
3. Auditoria das tentativas bloqueadas.
4. Regras de Firestore negando escrita direta fora do usuario/local.

## Configuracao obrigatoria

~~~powershell
dart pub global activate flutterfire_cli
flutterfire configure
~~~

Depois publique as regras:

~~~powershell
firebase deploy --only firestore:rules
~~~
