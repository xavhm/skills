# Design Philosophy — fondations théoriques

Sources : *What's an Object?*, *Thinking Object*, *Domain Modeling*, *Information Management* — book.pragmatic-objects.com

## Sommaire
- [Un objet n'est pas une classe](#un-objet-nest-pas-une-classe)
- [Rôles vs objets](#rôles-vs-objets)
- [Encapsulation = liberté de changer](#encapsulation--liberté-de-changer)
- [Choréographie vs orchestration](#choréographie-vs-orchestration)
- [Domain-Driven Design & Bounded Contexts](#domain-driven-design--bounded-contexts)
- [Le problème du "gros modèle"](#le-problème-du-gros-modèle)
- [Gestion de l'information et connascence](#gestion-de-linformation-et-connascence)
- [Information publique vs représentation privée](#information-publique-vs-représentation-privée)

## Un objet n'est pas une classe

Les classes, l'héritage, le typage — ce sont des outils du langage, pas la définition de l'orienté objet. On peut écrire du code parfaitement objet en C (via les Abstract Data Types : un `struct` + des fonctions qui l'encapsulent) et du code parfaitement procédural en Java.

**Définition d'Alan Kay (père de l'OOP)** :
> OOP = **messaging** + **local retention/protection/hiding of state** + **extreme late-binding**.

Remarquez : ni "classe", ni même "objet" n'apparaît. L'idée centrale est le **passage de messages entre rôles**, pas la taxonomie de classes.

## Rôles vs objets

Ce qui définit un `Baker` ou un `Oven` dans le code, ce n'est pas "ce qu'ils sont" mais les messages qu'ils acceptent de recevoir. Le même objet peut jouer plusieurs rôles (un robot qui est à la fois `Baker` et `Oven`) ; deux objets différents peuvent jouer le même rôle. **L'identité de qui joue le rôle est un détail d'implémentation.**

Conséquence pratique : penser vos dépendances en **contrats/rôles** (`interface`), pas en implémentations concrètes.

## Encapsulation = liberté de changer

- Le **couplage** = combien un objet A sait sur un objet B. Plus A sait, moins B est libre de changer sans casser A.
- **Public contract** = méthodes + types de retour + arguments + protocole d'appel + préconditions/postconditions/invariants. Tout ce que le contrat expose devient une dette qu'il faut honorer indéfiniment.
- Design = penser aux **flux de communication et de dépendance** entre objets, contrat en premier — l'implémentation vient après.

## Choréographie vs orchestration

- **Orchestration** : un chef d'orchestre (service "God") connaît le déroulé complet et dit à chaque objet quoi faire. Risque : couplage fort, objets "stupides".
- **Choréographie** : chaque objet connaît sa partition et communique par messages/événements (pub-sub) sans chef. Les microservices sont l'incarnation moderne de la pensée objet : unités indépendantes, communication asynchrone, déployables séparément (→ pattern [Observability](patterns.md)).

Préférer la choréographie chaque fois que c'est possible.

## Domain-Driven Design & Bounded Contexts

- **Domain Modeling** : le code doit utiliser le **vocabulaire du métier** (noms/verbes des experts du domaine), pas un vocabulaire technique. Le code devient un **médium de communication** avant d'être un artefact technique.
- **Bounded Context** = un Component/Module dont le nom et le découpage ont un sens pour le métier (`Warehousing`, `Shipping`...). Un Bounded Context peut lui-même contenir des sous-modules.
- Règle clé : **minimiser les dépendances entre Bounded Contexts**, favoriser une communication **asynchrone** entre eux.
- Analogie SRP : un Bounded Context est aligné sur des **actors**/**business units**, pas sur des entités techniques.

## Le problème du "gros modèle"

Anti-pattern classique : une classe `Product` unique portant catalogue + stock + livraison. Problèmes :
- Classe/graphe d'objets énormes, chargés même quand on ne modifie qu'un champ.
- "Solutions" dangereuses : **partial loading** (propriétés à `null`, invisibles à la compilation) et **lazy loading** (roundtrips DB cachés, difficiles à raisonner).
- **Solution recommandée** : scinder en plusieurs modèles par Bounded Context (`CatalogProduct`, `WarehouseProduct`, `ShippingProduct`), chacun développé pour un cas d'usage précis. Ne pas chercher un modèle "universel".

## Gestion de l'information et connascence

Types de connaissance qu'un objet A peut avoir sur B (= autant de sources de couplage, dites **connascence**) :
- Les messages/méthodes que B expose.
- Les paramètres de chaque méthode (type, ordre, retour).
- L'ordre d'invocation requis (protocole).
- Les dépendances de B et leur ordre de construction.
- Le fonctionnement interne de B (le pire niveau).

**Règle** : objet-orientation = contrôler et réduire cette connaissance entre "citoyens" du système (= *balancing dependencies*, R.C. Martin).

Rappel de perspective : "vos dépendants limitent votre liberté de changer" se lit toujours **du point de vue de l'objet dépendu**, pas du programmeur.

## Information publique vs représentation privée

Contre-intuitif mais central : **l'information n'est pas secrète, sa représentation l'est.**

Un `User` a un email — c'est un fait du domaine, pas un détail d'implémentation. Ce qui doit rester privé, c'est **comment** cet email est représenté (`string` brut vs objet `EmailAddress`).

```typescript
// Mauvais : expose la représentation (string) — casse si on migre vers EmailAddress
class User {
  getEmailAddress() { return this.emailAddress; } // coercition implicite en string
}

// Bon : le type de retour est un choix assumé et documenté, indépendant du champ interne
class User {
  getEmailAddress(): EmailAddress { return this.emailAddress; }
}
```

Deux usages différents, deux façons d'exposer :
- **À l'intérieur du domaine** → retourner l'objet riche (`EmailAddress`).
- **En dehors du domaine** (API JSON, stockage) → trois options : (1) lire directement en base côté requête/CQRS, (2) bindings ORM par réflexion, (3) pattern **[Snapshot](patterns.md#snapshot)**.

→ Voir aussi [`references/practices-encapsulation.md`](practices-encapsulation.md) pour l'application concrète (No Getters & Setters).
