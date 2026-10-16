# SOLID — vu par Pragmatic Objects

Source : *SOLID* — book.pragmatic-objects.com. SOLID est présenté comme un ensemble de principes **de conception objet**, pas de simples règles de style, qui traduisent 3 mécanismes de réduction de connaissance : **Abstraction**, **Encapsulation**, **Polymorphisme**.

## Sommaire
- [S — Single Responsibility](#s--single-responsibility-principle)
- [O — Open/Closed](#o--open-closed-principle)
- [L — Liskov Substitution](#l--liskov-substitution-principle)
- [I — Interface Segregation (non détaillé dans la source)](#i--interface-segregation-principle)
- [D — Dependency Inversion (non détaillé dans la source)](#d--dependency-inversion-principle)

## S — Single Responsibility Principle

❌ Mauvaise formulation : *"un objet ne fait qu'une seule chose"* — trop vague, inutilisable.

✅ Bonne formulation (Robert C. Martin) : **"un objet ne doit avoir qu'une seule raison de changer"**, et plus précisément **"un objet doit être responsable devant un seul acteur"**.

- **Acteur** = quiconque a un intérêt/pouvoir de décision sur pourquoi la classe change, regroupé par **business unit** (ex. Product Owner + CEO qui demandent tous deux une feature "au nom" des utilisateurs = même acteur).
- C'est le principe le plus subtil des 5 : identifier correctement les acteurs demande du travail de domaine, pas juste de la technique.
- Lien direct avec les **Bounded Contexts** (DDD) : les deux sont alignés sur les acteurs/business units.

## O — Open/Closed Principle

Une classe/module doit être **ouverte à l'extension, fermée à la modification**.

Méthode en 2 étapes, à réutiliser systématiquement :
1. **Identifier la commonalité/abstraction** : quel est le concept général derrière le besoin ? (pas "envoyer un email" mais "notifier") → créer une interface.
2. **Implémenter la variabilité** : autant de classes concrètes que de besoins (`SmtpMailer`, `LocalMailer` pour les tests, futur `SesMailer`...).

```typescript
interface Mailer {
  send(to: Recipient, subject: Subject, body: Body): Promise<void>;
}

class UserService {
  constructor(private readonly mailer: Mailer) {}
  createUser() { this.mailer.send(to, subject, body); }
}
```

`UserService` ignore totalement quelle implémentation reçoit le message. Ajouter un `SesMailer` n'impacte aucun code existant — seul le point d'instanciation (Factory / conteneur IoC) change.

> *"Factories are where conditionals go to die."* — Sandi Metz

→ Lien direct avec [`Separate Instantiation from Usage`](practices-structure.md#separate-instantiation-from-usage).

## L — Liskov Substitution Principle

Toute classe qui implémente/étend un type `T` doit **respecter intégralement le contrat de `T`**, pas seulement sa signature.

Le contrat inclut : valeurs acceptées, garanties de résultat (ex. "ne throw jamais sauf cas exceptionnel"), synchronicité, etc. Violation typique : une implémentation `Mailer` qui `throw` alors que le contrat ne le prévoyait pas, ou qui ne supporte qu'un sous-ensemble des cas (ex. texte seul, pas HTML).

**Deux façons de rester conforme à LSP** :
- Soit garantir que **aucune** implémentation ne lèvera d'erreur hors cas exceptionnel non anticipable (mémoire, stack overflow...).
- Soit **anticiper explicitement dans le contrat** que certaines implémentations ne supportent qu'un sous-ensemble, et le documenter/typer en conséquence.

## I — Interface Segregation Principle

*Non développé dans la source ("to be done").* Définition standard rappelée pour mémoire : préférer plusieurs interfaces petites et spécifiques à une interface large — un client ne doit dépendre que des méthodes qu'il utilise réellement. Cohérent avec le pattern [Command](patterns.md#command) du livre (chaque Command ne dépend que des collaborateurs strictement nécessaires à son action).

## D — Dependency Inversion Principle

*Non développé dans la source ("to be done").* Définition standard rappelée pour mémoire : dépendre d'abstractions, pas de concrétions ; les modules de haut niveau ne doivent pas dépendre des modules de bas niveau, les deux dépendent d'une interface. Cohérent avec le principe transversal du livre "penser en rôles/contrats, pas en implémentations" (voir [`design-philosophy.md`](design-philosophy.md#rôles-vs-objets)) et avec [`Declare Dependencies`](practices-structure.md#declare-dependencies).
