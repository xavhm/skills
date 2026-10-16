---
name: pragmatic-objects
description: Applique les principes de conception orientée objet "Pragmatic Objects" (encapsulation stricte, Tell-Don't-Ask, Domain-Driven Design, SOLID, Value Objects, composition plutôt qu'héritage). À UTILISER SYSTÉMATIQUEMENT dès que l'utilisateur conçoit des classes/objets, fait une revue de code orientée objet, discute d'architecture, de modélisation de domaine (DDD), de refactoring vers plus d'encapsulation, ou mentionne des getters/setters, de l'héritage, du couplage, SOLID, Value Objects, ou "Pragmatic Objects" / "Elegant Objects". S'applique à tout langage OO (TypeScript, Java, C#, PHP...).
---

# Pragmatic Objects — conception orientée objet

Synthèse du livre [Pragmatic Objects](https://book.pragmatic-objects.com/) d'Anthony (Ancyr Academy). Philosophie : la programmation orientée objet (OOP) n'est qu'une boîte à outils ; centrée sur le **comportement** et la **communication par messages**, pas sur le regroupement de données.

Ce ne sont pas des règles dogmatiques mais des **heuristiques** : à appliquer par défaut, à violer consciemment quand le contexte l'exige (TDD, contraintes de framework/ORM, frontières du système).

## Idée centrale

> Un objet n'est pas défini par ce qu'il **est**, mais par le service qu'il rend aux autres objets.

Deux conséquences directes à garder en tête à chaque conception de classe :

1. **Encapsulation d'abord** : un objet protège sa représentation interne. Les autres objets ne connaissent que son contrat public (méthodes), jamais sa structure.
2. **Réduire la connaissance ("knowledge")** : chaque bit d'information qu'un objet A connaît sur un objet B est du couplage. Moins on en sait sur les autres, plus on est libre de changer.

→ Détails et fondations théoriques : [`references/design-philosophy.md`](references/design-philosophy.md)

## Checklist rapide (à appliquer à chaque classe/objet)

| # | Vérifier que... | Si non → | Réf. |
|---|---|---|---|
| 1 | Aucun getter ne renvoie une valeur brute interne | Internaliser le comportement dans l'objet, ou exposer une interface maintenue (`toX()`, `asX()`) | practices-encapsulation |
| 2 | Aucun setter ; les mutations sont des verbes métier (`rename()`, pas `setName()`) | Remplacer par une méthode comportementale ; préférer retourner une nouvelle instance (immutabilité) | practices-encapsulation |
| 3 | Aucun `instanceof` / type-check / cast | Remplacer par du polymorphisme (méthode sur une interface commune) | practices-encapsulation |
| 4 | Pas de chaînage > 2 points (`a.b().c().d()`) | L'objet en sait trop sur la structure interne d'un autre → Loi de Déméter | practices-encapsulation |
| 5 | Pas de primitive "signifiante" nue (string d'email, number de durée, Date métier...) | Créer un Value Object dédié | practices-modeling |
| 6 | Aucun objet ne peut être construit dans un état invalide | Valider dans le constructeur (pattern **Always Valid**) | patterns |
| 7 | Pas de `null` qui traverse la couche domaine | Null uniquement aux frontières ; `Optional`/wrapping dès l'entrée (pattern **Airlocking**) | practices-modeling |
| 8 | Pas de booléen qui fait basculer le comportement d'une méthode (`if (this.isX) {...} else {...}`) | Objet **indécis** → extraire deux classes distinctes | practices-modeling |
| 9 | Pas d'héritage d'implémentation entre classes concrètes sans relation "is-a" solide | Préférer composition + délégation, ou interface | practices-structure |
| 10 | Chaque méthode est soit une commande (mute, ne retourne rien) soit une requête (retourne, ne mute rien) | Séparer (CQS) — exception : création avec retour d'ID/référence | practices-structure |
| 11 | Les dépendances d'un objet sont explicites (constructeur), jamais récupérées en cachette (statics, singletons, service locator) | Injecter au constructeur | practices-structure |
| 12 | La création d'objets polymorphiques est séparée de leur usage | Extraire une Factory / Abstract Factory | practices-structure |
| 13 | Les collections métier ont une classe dédiée, pas un array/Map nu qui se balade | Wrapper en `XxxCollection` avec méthodes métier | practices-modeling |
| 14 | Le nom d'une classe/variable reflète le vocabulaire du domaine métier (pas `UserService.doStuff()`, pas `dataObj`) | Revoir le nommage avec le domain expert | design-philosophy |

## Anti-patterns à repérer immédiatement (drapeaux rouges)

- **Getters/Setters bruts** exposant un champ privé sans valeur ajoutée.
- **`instanceof` / `typeof` / switch sur un type** en dehors d'une factory.
- **Classes utilitaires statiques** (`XxxHelper`, `XxxUtils`) — cf. `Abandon Statics`.
- **God Service** (`UserService` avec 15 méthodes sans cohésion) — préférer un objet **Command** par action (`RegisterUserCommand` + son `Handler`).
- **Modèle "large"** unique portant des responsabilités de plusieurs contextes métier (ex. `Product` qui gère catalogue + stock + livraison) — découper en Bounded Contexts.
- **Objets anémiques** : classes = sacs de champs + logique procédurale ailleurs.
- **Héritage pour réutiliser du code** entre classes concrètes sans relation conceptuelle "is-a" réelle — source de couplage maximal (voir *Inheritance Breaks Encapsulation*).
- **Mutation dispersée** dans une méthode longue (bug classique type kata *Gilded Rose*) — regrouper la mutation à un seul endroit, calculer un delta immuable avant.

## Comment utiliser cette skill

1. **Conception d'un nouveau modèle de domaine** (DDD, agrégats, value objects) → lire [`references/design-philosophy.md`](references/design-philosophy.md) (Domain Modeling, Bounded Contexts, gestion de l'information) puis [`references/practices-modeling.md`](references/practices-modeling.md).
2. **Revue de code / refactoring orienté objet** → parcourir la checklist ci-dessus, puis approfondir avec [`references/practices-encapsulation.md`](references/practices-encapsulation.md) et [`references/practices-structure.md`](references/practices-structure.md) selon le problème détecté.
3. **Question sur SOLID** → [`references/solid.md`](references/solid.md).
4. **Choix d'un pattern objet** (Value Object, Command, Wrapper, Snapshot...) → [`references/patterns.md`](references/patterns.md).
5. **Exemples de bout en bout** (avant/après, "magic number", conversion Celsius/Fahrenheit, réservation d'école de conduite) → [`references/worked-examples.md`](references/worked-examples.md).

Chaque fichier de référence est autonome : ouvrir uniquement celui pertinent à la tâche en cours plutôt que tout charger.

## Résumé en une phrase

Concevoir des objets qui **se parlent par contrat** (méthodes/comportement), qui **protègent leur état**, qui **n'existent que pour servir d'autres objets**, et dont le vocabulaire **reflète le langage du métier** — pas celui de la base de données.
