using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests
{
    /// <summary>
    /// Guards the damage triangle in shared/tuning/combat.json against
    /// drifting from DamageTable.Default.
    ///
    /// The other tuning guard compares struct fields by reflection, which
    /// a table of multipliers is not, so this one walks the matrix. The
    /// reason is the same: Godot's web export cannot run C#, so the
    /// prototype reads these numbers rather than calling into sim/, and
    /// combat.md §4's triangle is the one thing in the design a player
    /// learns entirely by being hit. Two copies of it disagreeing would
    /// teach them something untrue.
    /// </summary>
    public class DamageTableFileTests
    {
        private static JsonElement Load()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null &&
                   !File.Exists(Path.Combine(dir.FullName, "shared", "tuning", "combat.json")))
                dir = dir.Parent;

            Assert.True(dir != null, "could not find shared/tuning/combat.json");
            var path = Path.Combine(dir!.FullName, "shared", "tuning", "combat.json");
            return JsonDocument.Parse(File.ReadAllText(path)).RootElement
                .GetProperty("damageTable");
        }

        [Fact]
        public void Every_armour_multiplier_matches_the_shared_file()
        {
            var json = Load();
            var types = new Dictionary<string, DamageType>
            {
                ["cut"] = DamageType.Cut,
                ["pierce"] = DamageType.Pierce,
                ["blunt"] = DamageType.Blunt,
            };
            var classes = new Dictionary<string, ArmorClass>
            {
                ["none"] = ArmorClass.None,
                ["light"] = ArmorClass.Light,
                ["mail"] = ArmorClass.Mail,
                ["plate"] = ArmorClass.Plate,
            };

            foreach (var (typeName, type) in types)
            {
                foreach (var (className, armor) in classes)
                {
                    var expected = DamageTable.Default.Against(type, armor);
                    var actual = json.GetProperty(typeName).GetProperty(className).GetSingle();
                    Assert.True(Math.Abs(actual - expected) < 0.0001f,
                        $"damageTable.{typeName}.{className} is {actual} in the file " +
                        $"and {expected} in DamageTable.Default.");
                }
            }
        }

        [Fact]
        public void Every_hit_location_matches_the_shared_file()
        {
            var json = Load();
            foreach (var (name, location) in new Dictionary<string, HitLocation>
            {
                ["torso"] = HitLocation.Torso,
                ["limb"] = HitLocation.Limb,
                ["head"] = HitLocation.Head,
            })
            {
                var expected = DamageTable.Default.At(location);
                var actual = json.GetProperty(name).GetSingle();
                Assert.True(Math.Abs(actual - expected) < 0.0001f,
                    $"damageTable.{name} is {actual} in the file and {expected} in code.");
            }
        }

        [Fact]
        public void Armour_is_always_worth_wearing()
        {
            // The rule the table exists to keep, restated where the file
            // can break it: every unarmoured entry must sit clear of every
            // armoured one. An earlier draft had blunt at 1.30 against bare
            // flesh and 1.25 against plate, which made plate almost
            // pointless against the exact weapon it should answer.
            var json = Load();
            foreach (var type in new[] { "cut", "pierce", "blunt" })
            {
                var bare = json.GetProperty(type).GetProperty("none").GetSingle();
                foreach (var armour in new[] { "light", "mail", "plate" })
                {
                    var worn = json.GetProperty(type).GetProperty(armour).GetSingle();
                    Assert.True(bare > worn + 0.2f,
                        $"{armour} only reduces {type} from {bare} to {worn} — " +
                        "not enough of a gap for anyone to bother wearing it");
                }
            }
        }
    }
}
