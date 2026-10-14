using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.Society;
using Xunit;

namespace Marrowmark.Sim.Tests.Society
{
    /// <summary>
    /// Guards shared/tuning/society.json against drifting from WarProfile.
    /// No prototype copy, deliberately: L88 mirrors only what the
    /// prototype exercises, and there is no war in Thornfield yet.
    /// </summary>
    public class SocietyTuningFileTests
    {
        private const string Canonical = "shared/tuning/society.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;
            Assert.True(dir != null, $"Could not find {Canonical}");
            return dir!.FullName;
        }

        [Fact]
        public void War_tuning_matches_the_shared_file() => AssertSection(WarProfile.Default, "war");

        [Fact]
        public void Property_tuning_matches_the_shared_file() => AssertSection(PropertyProfile.Default, "property");

        /// <summary>Every field in the section with the same value, and
        /// nothing in the section that is not a field.</summary>
        private static void AssertSection<T>(T profile, string sectionName) where T : struct
        {
            var root = JsonDocument
                .Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical)))
                .RootElement;
            Assert.True(root.TryGetProperty(sectionName, out var section),
                $"{Canonical} has no \"{sectionName}\"");

            var known = new System.Collections.Generic.HashSet<string>();
            foreach (var field in typeof(T).GetFields(BindingFlags.Public | BindingFlags.Instance))
            {
                var key = char.ToLowerInvariant(field.Name[0]) + field.Name.Substring(1);
                known.Add(key);
                Assert.True(section.TryGetProperty(key, out var found),
                    $"{Canonical} is missing \"{sectionName}.{key}\"");

                var expected = field.GetValue(profile);
                if (expected is float f) Assert.Equal(f, found.GetSingle(), 4);
                else if (expected is int i) Assert.Equal(i, found.GetInt32());
                else Assert.Fail($"Unhandled field type for {key}: {field.FieldType}");
            }

            foreach (var property in section.EnumerateObject())
                Assert.True(known.Contains(property.Name),
                    $"{Canonical} has \"{sectionName}.{property.Name}\", which is not a field on {typeof(T).Name}.");
        }
    }
}
