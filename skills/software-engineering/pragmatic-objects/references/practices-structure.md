# Pratiques — Structure & dépendances

Sources : *Inherit Wisely*, *Abandon Statics*, *Declare Dependencies*, *Separate Instantiation from Usage*, *Separate Commands & Queries* — book.pragmatic-objects.com

## Sommaire
- [Inherit Wisely](#inherit-wisely)
- [Abandon Statics](#abandon-statics)
- [Declare Dependencies](#declare-dependencies)
- [Separate Instantiation from Usage](#separate-instantiation-from-usage)
- [Separate Commands & Queries (CQS)](#separate-commands--queries-cqs)

## Inherit Wisely

**Thèse centrale (contre l'orthodoxie classique) : l'héritage d'implémentation casse l'encapsulation — c'est la forme de couplage la plus forte possible.**

### Pourquoi l'héritage casse l'encapsulation

Une sous-classe qui dépend du fonctionnement interne d'une classe parente (ex. `addAll()` qui appelle en interne `add()`) rend le parent prisonnier de son implémentation actuelle : le moindre refactoring interne du parent peut casser silencieusement toutes les sous-classes. Le couplage est **asymétrique et dangereux** : le parent ne connaît même pas ses enfants, mais doit néanmoins figer son implémentation pour ne pas les casser.

### Composition/délégation comme remède par défaut

Plutôt qu'un hook `protected` (`onAdd()`) qui force à rendre une classe `abstract` alors qu'elle devrait être instanciable telle quelle, préférer la **délégation via une interface** :

```typescript
interface IEventListener { onAdd(value: number): void; }

class Queue {
  private listener?: IEventListener;
  add(value: number) {
    this.array.push(value);
    this.listener?.onAdd(value); // observabilité objet, pas classe
  }
  setEventListener(listener: IEventListener) { this.listener = listener; }
}
```

Avantage : n'importe quel objet peut s'abonner **au runtime**, sans figer une hiérarchie de classes.

### Interface vs implémentation

Deux formes bien distinctes :
- **Implementation Inheritance** (`extends` une classe concrète) : dangereuse par défaut.
- **Interface Inheritance** (`implements` une interface) : contrat asymétrique et sûr — le client (`Queue`) impose le contrat, l'implémenteur (`Counter`) n'a d'autre choix que de s'y conformer, vérifié par le compilateur. C'est le mécanisme de couplage le plus faible et le plus sûr disponible.

### Quand l'héritage concret a du sens

L'héritage concret **peut** être légitime — mais seulement sous deux conditions cumulatives :

1. **Relation "is-a" réelle dans le modèle** (pas dans la réalité — dans *votre* modèle de code). `UsersCollection extends Collection<User>` : difficile de nier que c'est une `Collection`.
2. **"Extensions Only"** : la sous-classe **n'écrase, ne réécrit et n'annule jamais** une méthode existante du parent — elle se contente d'**ajouter** de nouvelles méthodes qui s'appuient uniquement sur le contrat public du parent.

```typescript
class UsersCollection extends Collection<User> {
  legalUsers(): User[] { /* n'utilise que get()/size() du contrat public */ }
}
```

**Composabilité (capacités transverses type "Observable")** : à l'inverse, une capacité réutilisable comme `Observable` **n'est pas** une relation "is-a" (`Dictionary` n'est pas un `Observable`, elle **est observable** — c'est une propriété, pas une nature). L'héritage y est un mauvais outil et consomme le seul slot d'héritage simple disponible ; préférer la composition/délégation (au prix, en TypeScript, de méthodes de forwarding manuelles — TS n'a pas de vrais traits/mixins).

### Règles synthétiques

| Relation | Autorisé ? |
|---|---|
| Interface extends Interface | ✅ |
| Abstract class implements Interface | ✅ |
| Abstract class extends Abstract class | ✅ |
| Concrete class implements Interface | ✅ (préféré, faible couplage) |
| Concrete class extends Abstract class | ✅ |
| Concrete class extends Concrete class | ⚠️ rarement, seulement si "is-a" + Extensions Only |

Dans une sous-classe : **ne jamais** réécrire ou annuler une méthode héritée ; n'implémenter que les méthodes abstraites/prévues pour être surchargées ; n'ajouter que des méthodes nouvelles.

## Abandon Statics

Énoncé source (page volontairement courte) : *"se débarrasser de toute classe/méthode statique qui n'est pas un constructeur statique."*

Interprétation pragmatique cohérente avec le reste du corpus :
- Un `static` non-constructeur (`XxxHelper.doStuff()`, `XxxUtils`) est une fonction procédurale déguisée : elle n'a pas d'état, pas de collaborateurs injectés, donc pas de possibilité de substitution/polymorphisme (violation implicite de DIP/OCP).
- **Exception légitime : les constructeurs statiques** (`Duration.fromHours(2)`, `Duration.fromSeconds(120)`) — ils créent une instance, n'exposent aucune logique métier statique, et améliorent l'expressivité de la création d'objets. On les retrouve dans tout le corpus (`Duration`, `Seconds`, `DepartureDate.create`).
- Un service statique ne peut pas être remplacé par une autre implémentation (pas d'interface derrière un appel statique) → viole directement l'Open/Closed Principle et interdit le test par substitution (cf. exemple `Mailer` dans [`solid.md`](solid.md#o--open-closed-principle)).

## Declare Dependencies

Énoncé source (page volontairement courte) : *"révéler ses dépendances dans son interface ; les rendre explicites pour faciliter le raisonnement sur le code."*

Application concrète déjà illustrée ailleurs dans le corpus :
```typescript
class DepartureDate {
  static create(date: Date, now: Date) { /* now injecté, pas lu via Date.now() en interne */ }
}
```
En passant `now` en paramètre plutôt qu'en le lisant depuis une horloge globale, la classe devient testable et son besoin de collaborateur est visible **rien qu'en lisant la signature** — pas besoin d'ouvrir le corps de la méthode. Généralisation : tout ce dont un objet a besoin (horloge, générateur aléatoire, repository...) doit être injecté au constructeur ou en paramètre, jamais résolu en interne via un singleton/global/`new` caché.

## Separate Instantiation from Usage

⚠️ S'applique aux **objets polymorphiques** (qui implémentent une interface avec plusieurs implémentations possibles) — pas systématiquement à toute création d'objet, sauf si le processus de création est lui-même complexe.

Problème : si un objet **décide quelle implémentation utiliser** *et* **l'utilise**, il viole SRP (2 vecteurs de changement : "quelle règle choisir" vs "comment calculer") et OCP (ajouter un nouveau cas oblige à modifier la classe).

```typescript
// Mauvais : TaxCalculator décide ET utilise
class TaxCalculator {
  calculateTax(entity: Entity, income: Income) {
    // logique de sélection de policy mélangée au calcul
  }
}

// Bon : une Abstract Factory sépare la sélection de l'usage
class TaxCalculationPolicies {
  get(entity: Entity): TaxCalculationPolicy { /* règle de sélection isolée */ }
}
class TaxCalculator {
  constructor(private readonly policies: TaxCalculationPolicies) {}
  calculateTax(entity: Entity, income: Income) {
    const policy = this.policies.get(entity);
    policy.calculate(entity, income);
  }
}
```

Ajouter un nouveau type d'entité (nouvelle policy) ne touche plus que la Factory — jamais le `TaxCalculator`.

## Separate Commands & Queries (CQS)

Chaque méthode d'une classe est **soit** une commande (mute l'état, ne retourne rien), **soit** une requête (retourne une valeur, ne mute rien) — **jamais les deux**.

```typescript
user.age();          // Query — pas de mutation
user.rename("Jean");  // Command — pas de retour de valeur
```

**Seule exception acceptable** : une commande qui crée un nouvel objet et doit en retourner une **référence** pour usage ultérieur (ticket de caisse, ID de job dans une queue de messages). Dans ce cas précis, retourner l'ID/référence ne viole pas l'esprit du principe — on ne renvoie pas un *état*, on renvoie un *ticket*.
