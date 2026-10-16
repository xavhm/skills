---
name: pragmatic-objects
description: Concevoir des objets et classes TypeScript avec des règles pragmatiques d'encapsulation, de validité et de composition. À appliquer lors de la création ou de la modification d'objets métier, de value objects et de leurs contrats.
---

# Pragmatic Objects

Appliquer ces règles aux nouveaux objets TypeScript et aux objets modifiés dans le périmètre demandé. Ce sont des choix par défaut : respecter les contraintes du projet sans imposer une architecture complète.

## Règles

1. **Choisir la forme la plus simple.** Utiliser un objet littéral avec un `type` ou une `interface` pour des données sans comportement (DTO, configuration, résultat). Créer une classe ou une factory avec état privé lorsqu'il faut protéger des invariants ou porter un comportement métier. Garder les calculs indépendants sous forme de fonctions pures.

2. **Nommer selon le métier.** Donner à chaque objet un rôle cohérent et des méthodes exprimant une intention : `reserve()`, `rename()`, `deposit()`. Éviter les objets fourre-tout (`Manager`, `Utils`, services sans cohésion) et les modèles universels couvrant plusieurs contextes métier.

3. **Protéger la représentation interne.** Garder l'état privé et déplacer les règles dans l'objet qui le possède : `user.deposit(amount)` plutôt que `user.wallet.balance += amount`. Éviter les getters/setters mécaniques et la navigation dans les détails internes des collaborateurs. Les requêtes et conversions explicites (`canReserve()`, `toSeconds()`) restent légitimes ; renommer un getter ne suffit pas à encapsuler.

4. **Garantir un état valide.** Vérifier les invariants à la construction ou dans une factory, puis à chaque transition. Valider avant de muter ; un échec laisse l'objet inchangé. Éviter les objets partiellement initialisés et les appels obligatoires à `init()`. Valider les données externes à l'exécution : les types TypeScript ne les valident pas.

5. **Créer des value objects quand ils apportent une règle.** Encapsuler les valeurs portant validation, unités, calculs ou comparaisons métier (`Duration`, `Money`). Les rendre immuables, retourner une nouvelle valeur après une opération et comparer par valeur avec `equals()`, pas par référence avec `===`. Ne pas envelopper automatiquement chaque primitive ou collection ; créer une collection métier si elle porte ses propres règles.

6. **Maîtriser les mutations et l'absence.** Préférer `readonly`, en sachant qu'il est superficiel ; copier les tableaux, objets ou `Date` mutables reçus ou exposés si nécessaire. Garder les requêtes sans effet de bord et les mutations explicites. Représenter une absence légitime par une union (`User | undefined`) ou un résultat discriminé, sans `!` ou cast pour la masquer.

7. **Rendre les dépendances explicites.** Passer les collaborateurs, l'horloge et les sources d'aléatoire au constructeur ou en paramètre. Utiliser de petits contrats adaptés au consommateur lorsque la substitution est utile. Éviter les dépendances globales cachées ; garder l'assemblage des implémentations hors de leur usage. Les factories nommées (`Duration.fromMinutes()`) sont utiles sans imposer une factory à chaque objet.

8. **Préférer la composition.** Déléguer plutôt qu'hériter pour réutiliser du code. Toute implémentation doit respecter le contrat annoncé, y compris erreurs et effets de bord. Extraire une stratégie lorsque des variantes de comportement se répètent ; conserver les unions discriminées et leur narrowing pour des états ou données alternatifs. Un booléen ou un `switch` ne justifie pas seul de nouvelles classes.

9. **Expliciter les frontières.** Utiliser DTO, conversions ou snapshots pour l'API et la persistance, sans exposer de références mutables internes. Toute reconstruction doit rétablir les invariants. Ne pas imposer CQRS, événements, wrappers ou Command/Handler pour un besoin simple.

Avant de terminer, vérifier : rôle clair, état toujours valide, contrat public minimal, dépendances visibles et aucune abstraction sans besoin concret.
