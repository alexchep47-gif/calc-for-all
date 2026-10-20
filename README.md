# Calc For All  v1.1

Calculatrice Android Flutter avancée : scientifique + graphiques + nombres complexes + **étude de fonction complète**.

## Fonctionnalités

- Calculatrice scientifique (sin, cos, log, √, π, fractions a/b…)
- Tracé de courbes interactif
- **Étude de fonction** : domaine, période, extremums, asymptotes, tableau de variation, symétrie + explications
- Export du plan d’étude en **PDF**
- Nombres complexes
- Historique
- Thème clair / sombre + animations
- 100 % hors ligne

## Compilation (GitHub Actions)

1. Va sur l’onglet **Actions**
2. Clique sur **Build APK** → **Run workflow**
3. Attends la fin (vert)
4. Télécharge l’artefact `calc-for-all-apk`
5. Installe l’APK

## Structure

```
lib/
  main.dart
  core/
  data/
  features/
    calculator/
    graph/          ← étude de fonction
    complex/
    history/
    settings/
  widgets/
```

Développé pour être compilé uniquement depuis un téléphone + GitHub.
