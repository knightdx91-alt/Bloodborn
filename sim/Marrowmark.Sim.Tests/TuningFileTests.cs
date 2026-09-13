using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests
{
    /// <summary>
    /// Guards shared/tuning/combat.json against drifting from the C#
    /// defaults it mirrors.
    ///
    /// This exists because Godot's web export cannot run C#, so the
    /// prototype re-implements these rules in GDScript and reads its
    /// numbers from that file. Duplicated logic is a cost taken knowingly;
    /// duplicated tuning would be a slow disaster, because tuning is the
    /// part that changes daily once there is a controller in hand. If the
    /// two ever disagree, the build fails here rather than in a playtest
    /// six weeks later.
    ///
    /// The comparison is by reflection on purpose: adding a field to a
    /// profile without adding it to the file fails, which is the case that
    /// would otherwise slip through.
    /// </summary>
    public class TuningFileTests
    {
        private const string Canonical = "shared/tuning/combat.json";

        /// <summary>The Godot project cannot load anything above res://.</summary>
        private const string PrototypeCopy = "prototype/rules/combat.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;

            Assert.True(dir != null,
                $"Could not find {Canonical} above " + AppContext.BaseDirectory);
            return dir!.FullName;
        }

        private static JsonElement Load() =>
            JsonDocument.Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical))).RootElement;

        private static string CamelCase(string name) =>
            char.ToLowerInvariant(name[0]) + name.Substring(1);

        private static void AssertMatches<T>(T profile, string section) where T : struct
        {
            var json = Load().GetProperty(section);

            foreach (var field in typeof(T).GetFields(BindingFlags.Public | BindingFlags.Instance))
            {
                var key = CamelCase(field.Name);

                Assert.True(
                    json.TryGetProperty(key, out var value),
                    $"shared/tuning/combat.json is missing \"{section}.{key}\", which exists " +
                    $"on {typeof(T).Name}. Add it, or the prototype will silently use a " +
                    "different number from the server.");

                var expected = (float)field.GetValue(profile)!;
                Assert.True(
                    Math.Abs(value.GetSingle() - expected) < 0.0001f,
                    $"shared/tuning/combat.json has {section}.{key} = {value.GetSingle()}, " +
                    $"but {typeof(T).Name}.Default has {expected}.");
            }
        }

        [Fact]
        public void Stamina_tuning_matches_the_shared_file() =>
            AssertMatches(StaminaProfile.Default, "stamina");

        [Fact]
        public void Dodge_tuning_matches_the_shared_file() =>
            AssertMatches(DodgeProfile.Default, "dodge");

        [Fact]
        public void The_prototypes_copy_is_identical_to_the_canonical_file()
        {
            var root = RepoRoot();
            var canonical = File.ReadAllText(Path.Combine(root, Canonical));
            var copy = File.ReadAllText(Path.Combine(root, PrototypeCopy));

            Assert.True(
                canonical == copy,
                $"{PrototypeCopy} has drifted from {Canonical}. The canonical file is " +
                $"the one to edit; then `cp {Canonical} {PrototypeCopy}`. The copy only " +
                "exists because Godot cannot load anything above res://.");
        }

        [Fact]
        public void The_shared_file_carries_no_numbers_nobody_owns()
        {
            // The other direction: a key in the file with no field behind it
            // is either a typo or a leftover, and in both cases the
            // prototype is reading something the server does not have.
            var pairs = new (string section, Type type)[]
            {
                ("stamina", typeof(StaminaProfile)),
                ("dodge", typeof(DodgeProfile)),
            };

            foreach (var (section, type) in pairs)
            {
                var known = new System.Collections.Generic.HashSet<string>();
                foreach (var f in type.GetFields(BindingFlags.Public | BindingFlags.Instance))
                    known.Add(CamelCase(f.Name));

                foreach (var property in Load().GetProperty(section).EnumerateObject())
                {
                    Assert.True(
                        known.Contains(property.Name),
                        $"shared/tuning/combat.json has \"{section}.{property.Name}\", which " +
                        $"is not a field on {type.Name}.");
                }
            }
        }
    }
}
